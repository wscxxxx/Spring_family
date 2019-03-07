package com.test1.Beans_2;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class Domain {
    public static void main(String[] args) {
        ApplicationContext ctx=new ClassPathXmlApplicationContext("application.xml");
        Chinese c= (Chinese) ctx.getBean("Chinese",Person.class);
        c.say();


        Americat a= (Americat) ctx.getBean("American",Person.class);
        a.say();
    }
}
