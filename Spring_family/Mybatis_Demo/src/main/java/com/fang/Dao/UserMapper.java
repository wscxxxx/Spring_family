package com.fang.Dao;

import com.fang.pojo.User;

import java.util.List;

public interface UserMapper {

    public User getUser();
    public void addUser(User user);
    public int gUser();
    public List<User> selectAll();
}
