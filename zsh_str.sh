#!/bin/zsh
# str1="abc"
# str2="bef"
# str2+=$str1
# echo $str2
# str3=$str1$str2
# echo $str3
# str="abcdef"
# echo $str[2,4]
# echo $str[2,-1]
# echo ${str:1:3}
# str="abcdeabcde"
# # 删除左端匹配到的内容，最小匹配
# echo ${str#*c}
# # 删除右端匹配到的内容，最小匹配
# echo ${str%d*}
# 删除左端匹配到的内容，最大匹配
# echo ${str##*c}
# # 删除右端匹配到的内容，最大匹配
# echo ${str%%d*}
# str="abcdeff"
#大写I和小写i都是从左往右找 教程上不对 
# i：在参数里按 pattern 找到第一个匹配的下标（index）
# I：在参数里按 pattern 找到最后一个匹配的下标（index）
#但是I找不到返回0，小写i找不到返回数组大小+1
# echo $str[(I)f]
# echo $str[(i)f]
# echo $str[(i)x]
# echo $str[(I)x]
#遍历字符
# str=abcd
# for i ({1..${#str}}) {
#   echo $str[$i]
# }
# #字符串替换
# str=abcabc
# # 只替换找到的第一个
# echo ${str/bc/ef}
# # 删除匹配到的第一个
# echo ${str/bc}
# # 替换所有找到的
# echo ${str//bc/ef}
str=abcABCabcABCabc