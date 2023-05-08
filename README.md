#### BOOT

#### 加载内核

#### 进入内核

#### 中断


#### 磁盘驱动

查看磁盘文件的内容
> fdisk -l ./hd80M.img

使用 fdisk 命令进行分
> fdisk ./hd80M.img
> m 显示菜单命令
> n 创建分区
> x进入 extra functions 菜单
> m 显示子功能菜单
> c 设置柱面数162
> h 设置磁头数16
> r 返回到上一级菜单