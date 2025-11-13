//   CustomPinchCollectionView.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/13
//   

import UIKit

// MARK: - 数据模型
struct GridItem {
    let id: String
    var title: String
    var isSelected: Bool = false
}

// MARK: - 拖拽管理器
class DragManager {
    var draggingIndexPaths: Set<IndexPath> = []
    var draggingViews: [UIView] = []
    var initialCenters: [IndexPath: CGPoint] = [:]
    
    func startDragging(indexPaths: Set<IndexPath>, from collectionView: UICollectionView) {
        draggingIndexPaths = indexPaths
        
        for indexPath in indexPaths {
            guard let cell = collectionView.cellForItem(at: indexPath) as? GridCell else { continue }
            
            // 创建拖拽视图
            if let draggingView = cell.snapshotView(afterScreenUpdates: false) {
                draggingView.center = cell.center
                collectionView.addSubview(draggingView)
                draggingViews.append(draggingView)
                initialCenters[indexPath] = cell.center
                
                // 隐藏原始 cell
                cell.alpha = 0.3
                
                // 添加浮动动画
                UIView.animate(withDuration: 0.2) {
                    draggingView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    draggingView.alpha = 0.8
                }
            }
        }
    }
    
    func updateDragging(translation: CGPoint, in collectionView: UICollectionView) {
        for (index, indexPath) in draggingIndexPaths.enumerated() {
            guard index < draggingViews.count,
                  let initialCenter = initialCenters[indexPath] else { continue }
            
            let newCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )
            draggingViews[index].center = newCenter
        }
    }
    
    func endDragging(in collectionView: UICollectionView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            for (index, indexPath) in self.draggingIndexPaths.enumerated() {
                guard index < self.draggingViews.count,
                      let cell = collectionView.cellForItem(at: indexPath) as? GridCell,
                      let initialCenter = self.initialCenters[indexPath] else { continue }
                
                self.draggingViews[index].transform = .identity
                self.draggingViews[index].center = initialCenter
                cell.alpha = 1.0
            }
        }) { _ in
            self.cleanup(collectionView: collectionView)
            completion()
        }
    }
    
    func cleanup(collectionView: UICollectionView) {
        draggingViews.forEach { $0.removeFromSuperview() }
        draggingViews.removeAll()
        initialCenters.removeAll()
        
        // 恢复所有 cell 的透明度
        for indexPath in draggingIndexPaths {
            if let cell = collectionView.cellForItem(at: indexPath) as? GridCell {
                cell.alpha = 1.0
            }
        }
        
        draggingIndexPaths.removeAll()
    }
}

// MARK: - 自定义 Collection View
class AdvancedCollectionView: UICollectionView {
    
    // 缩放相关
    private var currentScale: CGFloat = 1.0
    private var customIsZooming: Bool = false
    
    // 选择相关
    private var longPressGesture: UILongPressGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    
    // 拖拽相关
    private var dragManager = DragManager()
    private var isMultiSelectMode: Bool = false
    private var selectedIndexPaths: Set<IndexPath> = []
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }
    
    private func setupGestures() {
        // 双指捏合缩放
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        addGestureRecognizer(pinchGesture)
        
        // 长按多选
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        addGestureRecognizer(longPressGesture)
        
        // 拖拽排序
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 2 // 允许双指拖拽
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            customIsZooming = true
            gesture.scale = currentScale
            
        case .changed:
            let scale = gesture.scale
            currentScale = min(max(scale, 0.5), 10.0)
            
            transform = CGAffineTransform(scaleX: currentScale, y: currentScale)
            
            if let layout = collectionViewLayout as? AdvancedFlowLayout {
                let is4x4Mode = currentScale >= 1.5
                layout.is4x4Mode = is4x4Mode
                layout.invalidateLayout()
            }
            
        case .ended, .cancelled:
            customIsZooming = false
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
                self.transform = .identity
            }
            
        default:
            break
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            guard let indexPath = indexPathForItem(at: location) else { return }
            
            // 进入多选模式
            isMultiSelectMode = true
            updateSelection(at: indexPath)
            
        case .changed:
            if isMultiSelectMode, let indexPath = indexPathForItem(at: location) {
                updateSelection(at: indexPath)
            }
            
        case .ended, .cancelled:
            // 保持多选模式，等待拖拽
            break
            
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            handlePanBegan(gesture)
            
        case .changed:
            handlePanChanged(gesture, translation: translation)
            
        case .ended, .cancelled:
            handlePanEnded(gesture)
            
        default:
            break
        }
        
        gesture.setTranslation(.zero, in: self)
    }
    
    private func handlePanBegan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        if isMultiSelectMode && !selectedIndexPaths.isEmpty {
            // 多选拖拽模式
            startMultiDrag(with: selectedIndexPaths)
        } else if gesture.numberOfTouches == 1 {
            // 单指单 cell 拖拽
            guard let indexPath = indexPathForItem(at: location),
                  let cell = cellForItem(at: indexPath) as? GridCell else { return }
            startSingleDrag(cell: cell, at: indexPath)
        }
    }
    
    private func handlePanChanged(_ gesture: UIPanGestureRecognizer, translation: CGPoint) {
        if isMultiSelectMode && !dragManager.draggingIndexPaths.isEmpty {
            // 更新多选拖拽
            dragManager.updateDragging(translation: translation, in: self)
            
            // 检查是否需要交换位置
            if let targetIndexPath = getTargetIndexPath(for: gesture) {
                performMultiItemSwap(to: targetIndexPath)
            }
        } else if let sourceIndexPath = dragManager.draggingIndexPaths.first {
            // 单 cell 拖拽更新
            updateSingleDrag(gesture: gesture, sourceIndexPath: sourceIndexPath)
        }
    }
    
    private func handlePanEnded(_ gesture: UIPanGestureRecognizer) {
        if isMultiSelectMode {
            endMultiDrag()
        } else {
            endSingleDrag()
        }
    }
    
    // MARK: - 单 Cell 拖拽
    private func startSingleDrag(cell: GridCell, at indexPath: IndexPath) {
        dragManager.startDragging(indexPaths: [indexPath], from: self)
    }
    
    private func updateSingleDrag(gesture: UIPanGestureRecognizer, sourceIndexPath: IndexPath) {
        let location = gesture.location(in: self)
        
        // 更新拖拽视图位置
        dragManager.updateDragging(translation: gesture.translation(in: self), in: self)
        
        // 检查是否移动到其他 cell 的位置
        if let targetIndexPath = indexPathForItem(at: location),
           targetIndexPath != sourceIndexPath,
           let dataSource = self.dataSource as? CustomPinchCollectionViewController {
            
            performSingleItemSwap(from: sourceIndexPath, to: targetIndexPath, dataSource: dataSource)
        }
    }
    
    private func endSingleDrag() {
        dragManager.endDragging(in: self) {
            self.dragManager.cleanup(collectionView: self)
        }
    }
    
    // MARK: - 多 Cell 拖拽
    private func startMultiDrag(with indexPaths: Set<IndexPath>) {
        dragManager.startDragging(indexPaths: indexPaths, from: self)
    }
    
    private func endMultiDrag() {
        dragManager.endDragging(in: self) {
            self.dragManager.cleanup(collectionView: self)
            // 保持多选模式，但清除拖拽状态
            self.reloadItems(at: Array(self.selectedIndexPaths))
        }
    }
    
    // MARK: - 交换逻辑
    private func performSingleItemSwap(from sourceIndexPath: IndexPath, to targetIndexPath: IndexPath, dataSource: CustomPinchCollectionViewController) {
        // 交换数据
        dataSource.swapItems(at: sourceIndexPath, and: targetIndexPath)
        
        // 移动 cell（带动画）
        performBatchUpdates({
            self.moveItem(at: sourceIndexPath, to: targetIndexPath)
            self.moveItem(at: targetIndexPath, to: sourceIndexPath)
        }) { _ in
            // 更新拖拽管理器中的 indexPath
            self.dragManager.draggingIndexPaths = [targetIndexPath]
            if let initialCenter = self.dragManager.initialCenters[sourceIndexPath] {
                self.dragManager.initialCenters[targetIndexPath] = initialCenter
                self.dragManager.initialCenters.removeValue(forKey: sourceIndexPath)
            }
        }
    }
    
    private func performMultiItemSwap(to targetIndexPath: IndexPath) {
        guard let dataSource = self.dataSource as? CustomPinchCollectionViewController else { return }
        
        let draggingSet = dragManager.draggingIndexPaths
        let targetItems = dataSource.getItems(at: targetIndexPath)
        
        // 计算移动方向
        let shouldMove = shouldMoveItems(from: draggingSet, to: targetIndexPath)
        
        if shouldMove {
            // 执行批量移动
            performBatchUpdates({
                dataSource.moveSelectedItems(draggingSet, to: targetIndexPath, in: self)
            }) { _ in
                // 更新选择状态
                self.updateSelectionAfterMultiMove(from: draggingSet, to: targetIndexPath)
            }
        }
    }
    
    private func shouldMoveItems(from sourceSet: Set<IndexPath>, to targetIndexPath: IndexPath) -> Bool {
        // 简单的移动逻辑：如果目标位置不在已选范围内，则移动
        return !sourceSet.contains(targetIndexPath)
    }
    
    private func updateSelectionAfterMultiMove(from oldIndexPaths: Set<IndexPath>, to referenceIndexPath: IndexPath) {
        // 这里可以实现更复杂的选择更新逻辑
        // 暂时保持原有选择状态
        reloadItems(at: Array(selectedIndexPaths))
    }
    
    private func getTargetIndexPath(for gesture: UIPanGestureRecognizer) -> IndexPath? {
        let location = gesture.location(in: self)
        return indexPathForItem(at: location)
    }
    
    // MARK: - 选择管理
    private func updateSelection(at indexPath: IndexPath) {
        guard let dataSource = self.dataSource as? CustomPinchCollectionViewController else { return }
        
        if selectedIndexPaths.contains(indexPath) {
            selectedIndexPaths.remove(indexPath)
        } else {
            selectedIndexPaths.insert(indexPath)
        }
        
        dataSource.toggleSelection(at: indexPath)
        reloadItems(at: [indexPath])
    }
    
    func clearSelection() {
        selectedIndexPaths.forEach { indexPath in
            if let dataSource = self.dataSource as? CustomPinchCollectionViewController {
                dataSource.clearSelection(at: indexPath)
            }
        }
        selectedIndexPaths.removeAll()
        reloadData()
    }
}

// MARK: - 手势识别器代理
extension AdvancedCollectionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == pinchGesture {
            return true
        }
        return false
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            return !customIsZooming
        }
        return true
    }
}

// MARK: - 自定义布局（保持不变）
class AdvancedFlowLayout: UICollectionViewFlowLayout {
    
    var is4x4Mode: Bool = false {
        didSet {
            invalidateLayout()
        }
    }
    
    override func prepare() {
        super.prepare()
        
        let totalSize: CGFloat = 100
        let spacing: CGFloat = is4x4Mode ? 2 : 1
        
        let itemsPerRow: CGFloat = is4x4Mode ? 4 : 8
        let availableWidth = totalSize - (spacing * (itemsPerRow - 1))
        let itemSize = availableWidth / itemsPerRow
        
        self.itemSize = CGSize(width: itemSize, height: itemSize)
        self.minimumInteritemSpacing = spacing
        self.minimumLineSpacing = spacing
        self.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        if is4x4Mode {
            for attribute in attributes {
                if let cell = collectionView?.cellForItem(at: attribute.indexPath) as? GridCell {
                    cell.showBorder = true
                }
            }
        }
        
        return attributes
    }
}

// MARK: - 自定义 Cell（添加多选状态）
class GridCell: UICollectionViewCell {
    
    static let reuseIdentifier = "GridCell"
    
    var showBorder: Bool = false {
        didSet {
            updateBorder()
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let selectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        view.isHidden = true
        view.layer.cornerRadius = 4
        return view
    }()
    
    private let multiSelectIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 4
        
        contentView.addSubview(selectionView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(multiSelectIndicator)
        
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        multiSelectIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            multiSelectIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            multiSelectIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            multiSelectIndicator.widthAnchor.constraint(equalToConstant: 6),
            multiSelectIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    override var isSelected: Bool {
        didSet {
            selectionView.isHidden = !isSelected
            multiSelectIndicator.isHidden = !isSelected
        }
    }
    
    private func updateBorder() {
        if showBorder {
            contentView.layer.borderWidth = 2
            contentView.layer.borderColor = UIColor.systemGray.cgColor
        } else {
            contentView.layer.borderWidth = 0.5
            contentView.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    
    func configure(with item: GridItem) {
        titleLabel.text = item.title
        isSelected = item.isSelected
        updateBorder()
    }
}

// MARK: - 视图控制器（添加多选支持）
class CustomPinchCollectionViewController: UIViewController {
    
    private var collectionView: AdvancedCollectionView!
    private var gridItems: [GridItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupCollectionView()
        setupUI()
    }
    
    private func setupData() {
        gridItems = (0..<64).map { index in
            GridItem(id: "\(index)", title: "\(index + 1)")
        }
    }
    
    private func setupCollectionView() {
        let layout = AdvancedFlowLayout()
        layout.scrollDirection = .vertical
        
        collectionView = AdvancedCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .systemGray6
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: GridCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加说明标签
        let instructionLabel = UILabel()
        instructionLabel.text = "双指缩放 • 长按多选 • 单指/双指拖拽排序 • 双击取消选择"
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        instructionLabel.textColor = .systemGray
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 添加双击手势取消选择
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func handleDoubleTap() {
        collectionView.clearSelection()
    }
    
    // 数据操作方法
    func swapItems(at sourceIndexPath: IndexPath, and targetIndexPath: IndexPath) {
        gridItems.swapAt(sourceIndexPath.item, targetIndexPath.item)
    }
    
    func toggleSelection(at indexPath: IndexPath) {
        gridItems[indexPath.item].isSelected.toggle()
    }
    
    func clearSelection(at indexPath: IndexPath) {
        gridItems[indexPath.item].isSelected = false
    }
    
    func getItems(at indexPath: IndexPath) -> GridItem {
        return gridItems[indexPath.item]
    }
    
    func moveSelectedItems(_ selectedIndexPaths: Set<IndexPath>, to targetIndexPath: IndexPath, in collectionView: UICollectionView) {
        // 获取选中的 items
        let selectedItems = selectedIndexPaths.map { gridItems[$0.item] }
        let selectedIndices = selectedIndexPaths.map { $0.item }.sorted()
        
        // 获取目标位置
        let targetIndex = targetIndexPath.item
        
        // 移除选中的 items
        for index in selectedIndices.reversed() {
            gridItems.remove(at: index)
        }
        
        // 计算新的插入位置
        let insertionIndex = targetIndex >= selectedIndices.first! ?
            targetIndex - selectedIndices.count + 1 : targetIndex
        
        // 插入 items
        gridItems.insert(contentsOf: selectedItems, at: insertionIndex)
        
        // 更新 collection view
        collectionView.reloadData()
    }
}

// MARK: - Collection View 数据源和代理
extension CustomPinchCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gridItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCell.reuseIdentifier, for: indexPath) as! GridCell
        cell.configure(with: gridItems[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 处理点击选择
        if let advancedCollectionView = collectionView as? AdvancedCollectionView {
            // 通过长按手势管理选择
            return
        }
    }
}

