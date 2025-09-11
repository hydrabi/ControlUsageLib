#!/bin/zsh
# cat /Users/bizhifeng/Documents/code/Shell/a.txt >> /Users/bizhifeng/Documents/code/Shell/b.txt
#(())用于比较数值
num=1234
((num == 123)) && echo good
#(( 里边可以使用与（&&）或（||）非（!）操作符
((num == 1 || num == 123)) && echo "或"
#大于等于
((num >= 123)) && echo "大于等于"
#小于
((num < 124)) && echo "小于"
if ((num > 3 && num + 3 < 10)) {
    echo $num
} elif ((num == 123)) {
    echo "num=123"
} else {
    echo "num不等于123"
}
#[[ ]] 用于比较字符串、判断文件等
str="abc"
if [[ "$str" == "abc" || "$str" == "value" ]] { 
    echo "$str" 
}
# for 循环主要用于枚举，这里的括号是 for 的特有用法，不是在子 shell 执行。括号内是字符串（可放多个，空格隔开）、数组（可放多个）或者哈希表（可放多个，哈希表是枚举值而不是键）。i 是用于枚举内容的变量名，变量名随意。
# for i (aa bb cc) {
#     echo $i
# }
# 枚举当前目录的 txt 文件
# for i (*.txt) {
#     echo $i
# }
# 枚举数组
# array=(aa bb cc)
# for i ($array) {
#     echo $i
# }
# 经典的 c 风格 for 循环
# for ((i=0;i<10;i++)) {
#     echo $i
# }

# 样例，{1..10} 可以生成一个 1 到 10 的数组
# for i ({1..10}) {
#     echo $i
# }

# repeat 语句用于循环固定次数，n 是一个整数或者内容为整数的变量。
# repeat 5 {
#     echo "repeat"
# }

# 分支逻辑用 if 也可以实现，但 case 更适合这种场景，并且功能更强大。
# ;; 代表结束 case 语句，;& 代表继续执行紧接着的下一个匹配的语句（不再进行匹配），;| 代表继续往下匹配看是否有满足条件的分支。
# i=2
# case $i {
#     (1)
#     echo 1
#     ;;
#     (2)
#     echo 2
#     # 继续执行下一个
#     ;&
#     (3)
#     echo 3
#     # 继续向下匹配
#     ;|
#     (4)
#     echo 4
#     ;;
#     (*)
#     echo other
#     ;;
# }

# select 语句是用于根据用户的选择决定分支的语句，语法和 for 语句差不多，如果不 break，会循环让用户选择。
select i (aa bb cc) {
    echo $i
    break
}