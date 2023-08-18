# Authorization Server with Spring Security

The content of this repository is explained in my Youtube channel.

https://youtube.com/playlist?list=PLab_if3UBk9-AArufc8CryyhSDVqkNT-U

## Run on Localhost

To be able to run the project on localhost, make sure you've followed the next steps.

### Backend alias

The following lines must be added in ```/etc/hosts``` to avoid having the browser create the cookies for the same 
URL overriding values from the different backends.
```
127.0.0.1       backend-auth
127.0.0.1       backend-resources
```

### Local Database

No need for this, keycloak docker-compose starts it's own

### Keycloak

This branch does not have Keycloak! It attempts to do it all in pure Spring Boot / Security


### Starting up

```
backend-resources$ mvn spring-boot:run
frontend-react$ npm i
frontend-react$ npm run start
```

### Keycloak config for Suomifi auth

These match metadata ilta-test-metadata-keycloak-redirect-fixed.xml, which is in main repo branch ILTA-196-suomifi-saml-prototypes

```
1.  Create new realm (name it `evaka-customer` for example)
    -   Keys:
        -   Providers:
            -   `rsa-generated` -> Delete
            -   `rsa-enc-generated` -> Delete
            -   Add keystore... -> `rsa`
                -   Console Display Name: rsa `(default)`
                -   Priority: 0 `(default)`
                -   Enabled: On `(default)`
                -   Active: On `(default)`
                -   Algorithm: RS256 `(default)`
                -   Private RSA Key: `(Select file: ilta-test.key, or whichever corresponds to metadata)`
                -   X509 Certificate: `(Select file: ilta-test.crt, or whichever corresponds to metadata)`
                -   Key use: sig `(default)`
            -   Add provider -> `rsa-enc`
                -   Name: rsa-enc `(default)`
                -   Priority: 0 `(default)`
                -   Enabled: On `(default)`
                -   Active: On `(default)`
                -   Private RSA Key: `(Select file: ilta-test.key, or whichever corresponds to metadata)`
                -   X509 Certificate: `(Select file: ilta-test.crt, or whichever corresponds to metadata)`
                -   Algorithm: RSA-OAEP `(default)`
    -   Email:
        -   Host: `smtp`
        -   Port: `1025`
        -   Other as defaults
2.  Client settings as in video, plus maybe
    4.  Navigate to `Mappers` (tab) and create following mappers
        -   lastName
            -   Name: lastName
            -   Mapper Type: User Property
            -   Property: lastName
            -   Friendly Name: lastName
            -   SAML Attribute Name: lastName
            -   SAML Attribute NameFormat: Basic
        -   firstName
            -   Name: firstName
            -   Mapper Type: User Property
            -   Property: firstName
            -   Friendly Name: firstName
            -   SAML Attribute Name: firstName
            -   SAML Attribute NameFormat: Basic
        -   id
            -   Name: id
            -   Mapper Type: User Property
            -   Property: id
            -   Friendly Name: id
            -   SAML Attribute Name: id
            -   SAML Attribute NameFormat: Basic
        -   email
            -   Name: email
            -   Mapper Type: User Property
            -   Property: email
            -   Friendly Name: email
            -   SAML Attribute Name: email
            -   SAML Attribute NameFormat: Basic
        -   socialSecurityNumber
            -   Name: socialSecurityNumber
            -   Mapper Type: User Attribute **(!)**
            -   User Attribute: socialSecurityNumber
            -   Friendly Name: socialSecurityNumber
            -   SAML Attribute Name: socialSecurityNumber
            -   SAML Attribute NameFormat: Basic

3.  Add Identity provider
    - Navigate to `Identity Providers` -> `Add provider...` -> `SAML v2.0`
        -   Settings
        -   Can try to autoconfig using https://static.apro.tunnistus.fi/static/metadata/idp-metadata.xml, but there was some error that required at least manual fixes
            -   Display Name: suomifi-ilta-saml
            -   Service provider entity ID: https://ilta.112.fi/auth/dev/keycloak/redirect2 (or whichever metadata you are using)
            -   Identity provider metadata: https://testi.apro.tunnistus.fi/idp1
            -   Single Sign-On Service URL:
                -   test: https://testi.apro.tunnistus.fi/idp/profile/SAML2/Redirect/SSO
            -   Single Logout Service URL:
                -   test: https://testi.apro.tunnistus.fi/idp/profile/SAML2/POST/SLO
            -   NameID Policy Format: Transient
            -   Principal Type: Attribute [Friendly Name]
            -   Principal Attribute: nationalIdentificationNumber
            -   HTTP-POST Binding Response: On
            -   HTTP-POST Binding for AuthnRequest: Off (could also use On)
            -   HTTP-POST Binding Logout: On
            -   Want AuthnRequests Signed: On
            -   Want Assertions Signed: On
            -   Want Assertions encrypted: on
            -   Force authentication: Off
            -   Validate Signature: On
            -   Validating X509 Certificates:
                -   test: signing certificate from https://static.apro.tunnistus.fi/static/metadata/idp-metadata.xml
        -   Mappers
            -   givenName
                -   Name: givenName
                -   Sync Mode Override: force
                -   Mapper Type: Attribute Importer
                -   Friendly Name: givenName
                -   User Attribute Name: firstName
            -   sn
                -   Name: sn
                -   Sync Mode Override: force
                -   Mapper Type: Attribute Importer
                -   Friendly Name: sn
                -   User Attribute Name: lastName
            -   nationalIdentificationNumber
                -   Name: nationalIdentificationNumber
                -   Sync Mode Override: force
                -   Mapper Type: Attribute Importer
                -   Friendly Name: nationalIdentificationNumber
                -   User Attribute Name: socialSecurityNumber
```

### Client and user configuration

See youtube video for client configuration.

In addition to that, you need to add a user with some password.


## Chapter 1

In this first chapter I explain how the OAuth2 and OpenID connect protocols work. For that, I will create a example
with 3 backends. In the OAuth2 protocol, I need a client (backend-client), a resource server (backend-server) and the 
authorization server (backend-auth).

The backend-client is a registered client in the backend-auth. The user will grant a temporary access to some resources
(from backend-resources) to backend-client. To validate this access, backend-client will delegate to backend-auth the 
authentication of the user. Then backend-client will request resources from backend-resources with the token created by
backend-auth.

The main concept of OAuth2 is that the client will never handle the credentials of the user. This will be delegated
to backend-auth. Backend-auth could be an external entity which handles multiple clients connexions (as Google, 
Facebook, Github...). 

On the top of that, OpenID Connect will send a richer information about the authenticated user from backend-auth to
backend-client. This will reduce the communication between those to validate the identity and to obtain some 
profile information.


## Chapter 2

In this second chapter I use an application built on top of Spring Cloud Gateway as the Client Server. This application
will try to use the Resources Server using the OAuth2 protocol.

Most of the time, the Resource Server and Authorization Server are existing applications which are consumed by hundreds
and thousands of clients. The goal is the consume them from a custom application. I've chosen Spring Cloud Gateway as
this is a common entry point in a microservice architecture.


## Chapter 3

In this third chapter I use Keycloak as the authorization server. Keycloak will list all the clients and users. All
the authentication will be managed by Keycloak. I can easily add and configure clients, with their callback URLs, WebOrigins
and authorization protocols.

I can also add final users, manage their profile and password.

In this chapter I will connect my Spring Cloud Gateway as a client server to Keycloak. Then, connecter my resources server
to validate the JWT against Keycloak.


## Chapter 4

In this chpater I change the client. Instead of being Spring Cloud Gateway the client of my application, it will be a ReactJS
frontend. I still have a Spring Boot application as a resources server behind my Spring Cloud Gateway, and Keycloak as the
authorization server.

In this case, I can't get a client_id and client_secret to communicate with Keycloak when authenticating the final user. As
storing a client_id and client_secret in the frontend will lead to a security failure, as those keys will be available by 
everyone which has access to the frontend.

Instead, I must change the protocol used. I must tell to Keycloak that now my client is a public client, and I must also generate
a PKCE. The workflow changes a little bit. I still have the client_id, but no more client_secret. 

In the frontend, I use the library oidc-client to connect to Keycloak.

