package com.cobalt.common.dto;

import java.util.List;
import org.springframework.data.domain.Page;

public record PagedResponse<T>(
    List<T> data,
    Pagination pagination
) {

    public static <T> PagedResponse<T> of(Page<T> page) {
        return new PagedResponse<>(
            page.getContent(),
            new Pagination(
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages()
            )
        );
    }

    public record Pagination(
        int page,
        int size,
        long totalElements,
        int totalPages
    ) {
    }
}
