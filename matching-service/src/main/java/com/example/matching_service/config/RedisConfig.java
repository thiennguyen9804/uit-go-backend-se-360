package com.example.matching_service.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.GeoOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisConfig {
  @Value("${redis.host}")
  private String redisHost;

  @Value("${redis.port}")
  private int redisPort;

  @Bean
  LettuceConnectionFactory redisConnectionFactory() {
    return new LettuceConnectionFactory(new RedisStandaloneConfiguration(redisHost, redisPort));
  }

  @Bean
  @Primary
  RedisTemplate<String, String> redisTemplate(RedisConnectionFactory redisConnectionFactory) {
    RedisTemplate<String, String> template = new RedisTemplate<>();
    StringRedisSerializer stringSerializer = new StringRedisSerializer();

    template.setKeySerializer(stringSerializer);
    template.setValueSerializer(stringSerializer);
    template.setHashKeySerializer(stringSerializer);
    template.setHashValueSerializer(stringSerializer);
    template.setConnectionFactory(redisConnectionFactory);
    return template;
  }

  @Bean
  GeoOperations<String, String> geoOperations(RedisTemplate<String, String> redisTemplate) {
    return redisTemplate.opsForGeo();
  }

}
