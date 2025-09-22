package com.elgris.usersapi.service;

import com.elgris.usersapi.models.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

/**
 * Servicio que implementa el patrón Cache-Aside para usuarios
 */
@Service
public class UserCacheService {

    private static final Logger logger = LoggerFactory.getLogger(UserCacheService.class);
    
    private static final String USER_CACHE_KEY_PREFIX = "user:";
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    @Value("${cache.user.ttl:3600}")
    private long cacheTtlSeconds;

    /**
     * Obtiene un usuario del caché
     * @param username el nombre de usuario
     * @return el usuario si existe en caché, null si no existe
     */
    public User getUserFromCache(String username) {
        try {
            String key = USER_CACHE_KEY_PREFIX + username;
            Object cached = redisTemplate.opsForValue().get(key);
            
            if (cached != null) {
                logger.info("Cache HIT for user: {}", username);
                return (User) cached;
            } else {
                logger.info("Cache MISS for user: {}", username);
                return null;
            }
        } catch (Exception e) {
            logger.error("Error retrieving user from cache: {}", username, e);
            return null;
        }
    }

    /**
     * Guarda un usuario en el caché
     * @param user el usuario a guardar
     */
    public void putUserInCache(User user) {
        try {
            if (user != null && user.getUsername() != null) {
                String key = USER_CACHE_KEY_PREFIX + user.getUsername();
                redisTemplate.opsForValue().set(key, user, cacheTtlSeconds, TimeUnit.SECONDS);
                logger.info("User cached successfully: {}", user.getUsername());
            }
        } catch (Exception e) {
            logger.error("Error caching user: {}", user != null ? user.getUsername() : "null", e);
        }
    }

    /**
     * Elimina un usuario del caché
     * @param username el nombre de usuario a eliminar
     */
    public void evictUserFromCache(String username) {
        try {
            String key = USER_CACHE_KEY_PREFIX + username;
            redisTemplate.delete(key);
            logger.info("User evicted from cache: {}", username);
        } catch (Exception e) {
            logger.error("Error evicting user from cache: {}", username, e);
        }
    }

    /**
     * Verifica si Redis está disponible
     * @return true si Redis está disponible, false si no
     */
    public boolean isRedisAvailable() {
        try {
            redisTemplate.opsForValue().set("health-check", "ok", 10, TimeUnit.SECONDS);
            return true;
        } catch (Exception e) {
            logger.warn("Redis is not available: {}", e.getMessage());
            return false;
        }
    }
}
