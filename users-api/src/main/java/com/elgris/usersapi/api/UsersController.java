package com.elgris.usersapi.api;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.repository.UserRepository;
import com.elgris.usersapi.service.UserCacheService;
import io.jsonwebtoken.Claims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.LinkedList;
import java.util.List;

@RestController()
@RequestMapping("/users")
public class UsersController {

    private static final Logger logger = LoggerFactory.getLogger(UsersController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserCacheService userCacheService;


    @RequestMapping(value = "/", method = RequestMethod.GET)
    public List<User> getUsers() {
        List<User> response = new LinkedList<>();
        userRepository.findAll().forEach(response::add);

        return response;
    }

    @RequestMapping(value = "/{username}",  method = RequestMethod.GET)
    public User getUser(HttpServletRequest request, @PathVariable("username") String username) {

        Object requestAttribute = request.getAttribute("claims");
        if((requestAttribute == null) || !(requestAttribute instanceof Claims)){
            throw new RuntimeException("Did not receive required data from JWT token");
        }

        Claims claims = (Claims) requestAttribute;

        if (!username.equalsIgnoreCase((String)claims.get("username"))) {
            throw new AccessDeniedException("No access for requested entity");
        }

        // Implementación del patrón Cache-Aside
        logger.info("Attempting to retrieve user: {}", username);
        
        // 1. Intentar obtener del caché (Cache Hit/Miss)
        User cachedUser = userCacheService.getUserFromCache(username);
        if (cachedUser != null) {
            logger.info("Returning user from cache: {}", username);
            return cachedUser;
        }
        
        // 2. Cache Miss: obtener de la base de datos
        logger.info("Cache miss, retrieving from database: {}", username);
        User user = userRepository.findOneByUsername(username);
        
        // 3. Guardar en caché para futuras consultas
        if (user != null) {
            userCacheService.putUserInCache(user);
            logger.info("User cached for future requests: {}", username);
        }
        
        return user;
    }

}
