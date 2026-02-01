package com.cobalt.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
    T data,
    Meta meta
) {

    public static <T> ApiResponse<T> of(T data) {
        return new ApiResponse<>(data, new Meta(Instant.now(), UUID.randomUUID().toString()));
    }

    public record Meta(
        Instant timestamp,
        String requestId
    ) {
    }
}
