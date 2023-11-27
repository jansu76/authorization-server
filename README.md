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

### Starting up

```
backend-keycloak-auth$ docker compose up
backend-resources$ mvn spring-boot:run
frontend-react$ npm i
frontend-react$ npm run start
```

### Initial Keycloak configuration

Configuration is explained in youtube video + some extra configuration is needed for Suomifi-tunnistus:
- https://www.youtube.com/watch?v=hfeOqvHxHO8

In written form, do:

#### Create realm and OIDC client

1. login to http://backend-keycloak-auth:8080/ with keycloak credentials (see docker-compose.yml)
2. create new real `My_realm` (note accidental uppercase M, as opposed to lowercase in the video, to match other configuration)
3. (no need to create user my_user like in video)
4. create client scope, name = `message.read`, type = Default
5. create (OpenID connect) client, Client ID = `frontend_client` (deviation from video), give it also a name
   -  Client authentication = Off
   -  Authorization = Off 
   -  Authentication flow:
      - standard flow
      - direct access grants
   -  Valid redirect URIs: http://localhost:3000/signin-callback.html
   -  Web origins: http://localhost:3000
6. After Save:
   -  Proof Key for Code Exchange Code Challenge Method = S256
7. Check that client has client scope message.read

#### Configure realm `My_realm` settings

1. Realm settings -> keys
    -   Keys:
        -   Providers:
            -   `rsa-generated` -> Delete
            -   `rsa-enc-generated` -> Delete
            -   Add provider... -> `rsa`
                -   Console Display Name: rsa `(default)`
                -   Priority: 0 `(default)`
                -   Enabled: On `(default)`
                -   Active: On `(default)`
                -   Algorithm: RS256 `(default)`
                -   Private RSA Key: `(Select file: ilta-test.key, or whichever corresponds to metadata)`
                -   X509 Certificate: `(Select file: ilta-test.crt, or whichever corresponds to metadata)`
            -   Add provider -> `rsa-enc`
                -   Name: rsa-enc `(default)`
                -   Priority: 0 `(default)`
                -   Enabled: On `(default)`
                -   Active: On `(default)`
                -   Private RSA Key: `(Select file: ilta-test.key, or whichever corresponds to metadata)`
                -   X509 Certificate: `(Select file: ilta-test.crt, or whichever corresponds to metadata)`
                -   Algorithm: RSA-OAEP `(default)`
    -   Email:
        -   From: noreply@keycloak.local
        -   Host: `smtp`
        -   Port: `1025`
        -   Other as defaults

#### Add identity profiler for Suomifi authentication 

1. Add Identity provider
    - Navigate to `Identity Providers` -> `SAML v2.0`
        -   SAML entity descriptor: https://static.apro.tunnistus.fi/static/metadata/idp-metadata.xml -> Add
        -   This autofills some fields with correct values, e.g. Validating X509 Certificates
        -   After autofill, turn off entity descriptor use to be able to edit the wrong values
        -   `Show metadata` and check / fill these:
            -   Alias: suomifi-ilta-saml
            -   Display Name: suomifi-ilta-saml
            -   Service provider entity ID: https://ilta.112.fi/auth/dev/keycloak/redirect2 (or whichever metadata you are using)
            -   Identity provider entity ID: https://testi.apro.tunnistus.fi/idp1
            -   Single Sign-On Service URL: https://testi.apro.tunnistus.fi/idp/profile/SAML2/Redirect/SSO
            -   Single Logout Service URL: https://testi.apro.tunnistus.fi/idp/profile/SAML2/POST/SLO
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
        -   After Create, configure mappers
            -   givenName
                -   Name: givenName
                -   Sync Mode Override: force
                -   Mapper Type: Attribute Importer
                -   Friendly Name: firstName
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

#### Create first login flow to not ask user for missing information (= email address):

- Authentication -> first broker login -> action -> duplicate -> Name = ILTA first broker login
    - Change Review Profile to "Disabled"
- Change identity profile to use first login flow = ILTA first broker login

With this configuration, you should be able to login to the app with Suomifi-tunnistus, and execute a secure backend call using OIDC.

# Original documentation for tutorial chapters 1-4

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

