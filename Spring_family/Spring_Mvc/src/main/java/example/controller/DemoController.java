package example.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/home")
public class DemoController {

    @RequestMapping("/index")
    public String index(){
        return "index";
    }
}