package com.test1.Beans_2;

public class PersonFactory {
    public static Person getPerson(String arg){
        if (arg.equalsIgnoreCase("Chinese")){
            return new Chinese();
        }else if (arg.equalsIgnoreCase("American")){
            return new Americat();
        }else {
            return null;
        }
    }
}
