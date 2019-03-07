package com.test1.Beans_3;


/**
 * http://www.cnblogs.com/goodcheap
 *
 * @author: Wáng Chéng Dá
 * @create: 2017-03-02 19:30
 */
public class Car {

    private String brand;

    private double price;

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    public Car(String brand, double price) {
        this.brand = brand;
        this.price = price;
    }

    public Car() {
    }

    @Override
    public String toString() {
        return "Car{" +
                "brand='" + brand + '\'' +
                ", price=" + price +
                '}';
    }
}