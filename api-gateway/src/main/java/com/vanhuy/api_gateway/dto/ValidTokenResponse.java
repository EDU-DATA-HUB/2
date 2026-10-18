package com.vanhuy.api_gateway.dto;

public class ValidTokenResponse {
    private boolean valid;

    // Default constructor
    public ValidTokenResponse() {}

    public ValidTokenResponse(Boolean valid) {
        this.valid = valid;
    }

    public boolean isValid() {
        return valid;
    }

    public void setValid(boolean valid) {
        this.valid = valid;
    }
}
