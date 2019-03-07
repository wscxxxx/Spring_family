import com.test1.Beans_1.IntrduceDemo;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
public class testMain { public static void main(String[] args) {
    //创建Spring上下文（加载bean.xml）
    ApplicationContext acx= new ClassPathXmlApplicationContext("application.xml");

    //获取HelloWorld实例
    IntrduceDemo id=acx.getBean("IntrduceDemo",IntrduceDemo.class);
    id.setName("aaa");
    id.setAge(2);

//    IntrduceDemo idNEW=acx.getBean("IntrduceDemo",IntrduceDemo.class);
    // 调用方法
    id.intrduce();
//    idNEW.intrduce();
    //销毁实例对象
    ((ClassPathXmlApplicationContext) acx).close();
}
}
