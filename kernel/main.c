#include "print.h"
#include "init.h"
#include "debug.h"
#include "memory.h"
#include "../thread/thread.h"
#include "../device/console.h"
#include "../device/ioqueue.h"
#include "../device/keyboard.h"
#include "../userprog/process.h"
#include "../userprog/syscall-init.h"
#include "../lib/user/syscall.h"
#include "../lib/stdio.h"
#include "../fs/fs.h"
#include "../fs/dir.h"
#include "../userprog/fork.h"

void init(void);  

int main(void)
{
   put_str("I am kernel\n");
   init_all();

   // intr_enable(); //打开中断，使时钟中断起作用

   // struct stat obj_stat;
   // sys_stat("/",&obj_stat);
   // printf("/`s info\n i_no:%d\n size:%d\n filetype:%s\n",
   //       obj_stat.st_ino, obj_stat.st_size,
   //       obj_stat.st_filetype == 2 ? "directory" : "regular");

   // sys_stat("/dir1", &obj_stat);
   // printf("/dir1`s inof\n i_no:%d\n size:%d\n filetype:%s\n",
   //         obj_stat.st_ino, obj_stat.st_size,
   //         obj_stat.st_filetype == 2 ? "directory" : "regular");


   while (1)
   {
      // console_put_str("Main");
   };
   return 0;
}


/* init 进程 */
void init(void){

   printf("fork init\n");
   uint32_t ret_pid = fork();
   if(ret_pid){  //父进程 
      printf("i am father, my pid is %d, child pid is %d\n", getpid(), ret_pid);
   }else{   //子进程
      printf("i am child, my pid is %d, ret pid is %d\n",getpid(), ret_pid);
   }
   while(1);
}