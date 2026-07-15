package com.taskmanager.api.storage;

import com.taskmanager.api.user.AppUser;
import com.taskmanager.api.user.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/storage")
public class StorageController {
    private static final Set<String> ALLOWED_TYPES = Set.of(
        "image/jpeg", "image/png", "image/heic", "application/pdf"
    );

    private final S3Presigner presigner;
    private final UserRepository users;
    private final String bucket;
    private final Duration urlDuration;

    public StorageController(S3Presigner presigner, UserRepository users,
        @Value("${app.storage.bucket}") String bucket,
        @Value("${app.storage.upload-url-minutes}") long uploadURLMinutes) {
        this.presigner = presigner;
        this.users = users;
        this.bucket = bucket;
        this.urlDuration = Duration.ofMinutes(uploadURLMinutes);
    }

    @PostMapping("/upload-url")
    public UploadResponse createUploadURL(@Valid @RequestBody UploadRequest request) {
        if (!ALLOWED_TYPES.contains(request.contentType())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unsupported file type");
        }

        AppUser owner = findUser(request.ownerEmail());
        String safeName = request.fileName().replaceAll("[^a-zA-Z0-9._-]", "_");
        String objectKey = "users/%d/%s-%s".formatted(owner.getId(), UUID.randomUUID(), safeName);
        PutObjectRequest putRequest = PutObjectRequest.builder()
            .bucket(bucket)
            .key(objectKey)
            .contentType(request.contentType())
            .build();
        String uploadURL = presigner.presignPutObject(PutObjectPresignRequest.builder()
            .signatureDuration(urlDuration)
            .putObjectRequest(putRequest)
            .build()).url().toString();
        return new UploadResponse(uploadURL, objectKey, request.contentType());
    }

    @PostMapping("/download-url")
    public Map<String, String> createDownloadURL(@Valid @RequestBody DownloadRequest request) {
        AppUser owner = findUser(request.ownerEmail());
        String requiredPrefix = "users/%d/".formatted(owner.getId());
        if (!request.objectKey().startsWith(requiredPrefix)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Object does not belong to this account");
        }
        GetObjectRequest getRequest = GetObjectRequest.builder().bucket(bucket).key(request.objectKey()).build();
        String downloadURL = presigner.presignGetObject(GetObjectPresignRequest.builder()
            .signatureDuration(urlDuration).getObjectRequest(getRequest).build()).url().toString();
        return Map.of("downloadUrl", downloadURL);
    }

    @PutMapping("/profile-image")
    public Map<String, String> saveProfileImage(@Valid @RequestBody ProfileImageRequest request) {
        AppUser owner = findUser(request.ownerEmail());
        String requiredPrefix = "users/%d/".formatted(owner.getId());
        if (!request.objectKey().startsWith(requiredPrefix)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Object does not belong to this account");
        }
        owner.setProfileImageKey(request.objectKey());
        users.save(owner);
        return Map.of("objectKey", request.objectKey());
    }

    @GetMapping("/profile-image-url")
    public Map<String, String> getProfileImageURL(@RequestParam @Email String email) {
        AppUser owner = findUser(email);
        if (owner.getProfileImageKey() == null || owner.getProfileImageKey().isBlank()) {
            return Map.of();
        }
        GetObjectRequest getRequest = GetObjectRequest.builder()
            .bucket(bucket).key(owner.getProfileImageKey()).build();
        String downloadURL = presigner.presignGetObject(GetObjectPresignRequest.builder()
            .signatureDuration(urlDuration).getObjectRequest(getRequest).build()).url().toString();
        return Map.of("downloadUrl", downloadURL, "objectKey", owner.getProfileImageKey());
    }

    private AppUser findUser(String email) {
        return users.findByEmailIgnoreCase(email)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account not found"));
    }

    public record UploadRequest(@Email @NotBlank String ownerEmail, @NotBlank String fileName,
                                @NotBlank String contentType) {}
    public record UploadResponse(String uploadUrl, String objectKey, String contentType) {}
    public record DownloadRequest(@Email @NotBlank String ownerEmail, @NotBlank String objectKey) {}
    public record ProfileImageRequest(@Email @NotBlank String ownerEmail, @NotBlank String objectKey) {}
}
