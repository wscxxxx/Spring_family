package com.test1.Beans_1;

public class IntrduceDemo {
    //姓名
     private String name;
     //年龄
   private int age;
     public int getAge() {
    return age;
   }
   public void setAge(int age) {
         this.age = age;
     }
     public String getName() {
         return name;
     }
     public void setName(String name) {
         this.name = name;
     }

     /** * 自我介绍 */
     public void intrduce(){
         System.out.println("您好，我叫"+this.name+"今年"+this.age+"岁！");
     }
     public void init(){
         System.out.println("Bean初始化中。。。。。");

     }
     public void destroy(){
         System.out.println("Bean销毁。。。。。");
     }
}
