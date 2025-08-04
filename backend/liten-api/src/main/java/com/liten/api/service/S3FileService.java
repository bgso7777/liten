package com.liten.api.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.IOException;
import java.net.URL;
import java.time.Duration;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class S3FileService {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    public String uploadFile(MultipartFile file, String folder) throws IOException {
        String fileName = generateFileName(file.getOriginalFilename());
        String key = folder + "/" + fileName;

        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .contentLength(file.getSize())
                    .build();

            s3Client.putObject(putObjectRequest, 
                RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            log.info("파일 업로드 성공: {}", key);
            return key;
        } catch (Exception e) {
            log.error("파일 업로드 실패: {}", key, e);
            throw new RuntimeException("파일 업로드에 실패했습니다.", e);
        }
    }

    public void deleteFile(String key) {
        try {
            DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            s3Client.deleteObject(deleteObjectRequest);
            log.info("파일 삭제 성공: {}", key);
        } catch (Exception e) {
            log.error("파일 삭제 실패: {}", key, e);
            throw new RuntimeException("파일 삭제에 실패했습니다.", e);
        }
    }

    public String generatePresignedUrl(String key, Duration duration) {
        try {
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            // Presigned URL 생성 로직은 AWS SDK v2에서 다른 방식으로 구현
            // 여기서는 간단한 구조만 제공
            return String.format("https://%s.s3.%s.amazonaws.com/%s", 
                    bucketName, "ap-northeast-2", key);
        } catch (Exception e) {
            log.error("Presigned URL 생성 실패: {}", key, e);
            throw new RuntimeException("URL 생성에 실패했습니다.", e);
        }
    }

    public boolean fileExists(String key) {
        try {
            HeadObjectRequest headObjectRequest = HeadObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            s3Client.headObject(headObjectRequest);
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (Exception e) {
            log.error("파일 존재 확인 실패: {}", key, e);
            return false;
        }
    }

    public long getFileSize(String key) {
        try {
            HeadObjectRequest headObjectRequest = HeadObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            HeadObjectResponse response = s3Client.headObject(headObjectRequest);
            return response.contentLength();
        } catch (Exception e) {
            log.error("파일 크기 조회 실패: {}", key, e);
            return 0;
        }
    }

    private String generateFileName(String originalFilename) {
        String uuid = UUID.randomUUID().toString();
        String extension = "";
        
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        
        return uuid + extension;
    }
}