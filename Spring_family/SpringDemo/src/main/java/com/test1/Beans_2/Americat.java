package com.test1.Beans_2;

public class Americat implements Person {
   private String msg;

    public void setMsg(String msg) {
        this.msg = msg;
    }

    @Override
    public void say() {
        System.out.println("bbbbbb"+msg);
    }
}
