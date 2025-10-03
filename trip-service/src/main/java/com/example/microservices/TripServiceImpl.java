package com.example.microservices;

import org.springframework.stereotype.Service;

import com.example.microservices.proto.HelloReply;
import com.example.microservices.proto.HelloRequest;
import com.example.microservices.proto.TripServiceGrpc;
import io.grpc.stub.StreamObserver;

@Service
class TripServiceImpl extends TripServiceGrpc.TripServiceImplBase {

  @Override
  public void sayHello(HelloRequest request, StreamObserver<HelloReply> responseObserver) {
    HelloReply reply = HelloReply.newBuilder()
        .setContent("Hello from Trip Grpc Service")
        .build();
    responseObserver.onNext(reply);
    responseObserver.onCompleted();
  }

}
