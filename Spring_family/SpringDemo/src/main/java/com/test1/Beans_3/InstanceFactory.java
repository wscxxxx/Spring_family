package com.test1.Beans_3;


import java.util.HashMap;
import java.util.Map;

/**
 * 实例工厂方法
 * http://www.cnblogs.com/goodcheap
 *
 * @author: Wáng Chéng Dá
 * @create: 2017-03-02 20:02
 */
public class InstanceFactory {

    private Map<String, Car> cars = null;

    public InstanceFactory() {
        cars = new HashMap<String, Car>();
        cars.put("Ferrari", new Car("Ferrari", 25000000));
        cars.put("Maserati", new Car("Maserati", 2870000));
    }

    public Car getCar(String name) {
        return cars.get(name);
    }
}