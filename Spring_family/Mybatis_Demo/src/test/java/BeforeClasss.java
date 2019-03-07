import com.fang.pojo.User;
import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.junit.Before;
import org.junit.Test;


import java.io.InputStream;

import java.io.Reader;
import java.util.List;

public class BeforeClasss {

    SqlSession session;


    @Before
    public void initData() throws Exception {

        String resource="conf.xml";
      Reader reader = Resources.getResourceAsReader(resource);
        SqlSessionFactory factory=new SqlSessionFactoryBuilder().build(reader);
        session=factory.openSession();

    }

    /*
    查询
    */
//    @Test

//    插入
    @Test
    public void addUserTest(){

        User user1=new User();
        user1.setName("李强");
        user1.setAge("123");
        int count=session.insert("insert",user1);
        session.commit();
        System.out.println(count);

    }
//        public void selectDeptTest1(){
////        方法1
//        String statement = "com.fang.mapping.userMapper.getUser";//映射sql的标识字符串
//        //执行查询返回一个唯一user对象的sql
//        User user = session.selectOne(statement,1 );
//        System.out.println(user);
//
//        System.out.println("--------------------------------------------------------");
////        方法2
//        List<User> selectList=session.selectList("getAlluser");
//
//
//        for (User user1:selectList){
//            System.out.println(user1.getName());
//        }
//    }
    public static void main(String[] args) {
        BeforeClasss xx=new BeforeClasss();
//        xx.selectDeptTest1();
        xx.addUserTest();
    }
}
