package com.test1.Beans_3;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

/**
 * http://www.cnblogs.com/goodcheap
 *
 * @author: Wáng Chéng Dá
 * @create: 2017-03-02 19:41
 */
public class Domain2 {

    public static void main(String[] args) {

        ApplicationContext ctx = new ClassPathXmlApplicationContext("application.xml");

        Car car = (Car) ctx.getBean("car2");
        System.out.println(car);

    }
}
