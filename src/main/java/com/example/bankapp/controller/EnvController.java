@RestController
public class EnvController {

    @Value("${APP_COLOR:UNKNOWN}")
    private String color;

    @GetMapping("/env")
    public String env() {
        return color;
    }
}
