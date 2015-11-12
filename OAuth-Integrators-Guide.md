# Integrate with Copper using OAuth

We recommend you use one of our [SDKs at Copperworks](https://withcopper.com/apps) to build with Copper. If an SDK doesn’t yet exist for your preferred platform, or when flexibility is called for, we support API-based integrations through OAuth.

Copper conforms to OAuth 2.0 with OpenID Connect 1.0, two of the world's most popular standards. This means you should be able to find a simple way to talk to Copper no matter which platform or language you are working in.

## Before Getting Started

This document will take you through the basics of an OAuth integration with Copper. It assumes you already have a baseline knowledge of OAuth 2.0, and are looking for the meaty stuff like URLs, what's different, error cases and the like. If you don't yet understand this protocol, we recommend [a bit of study](https://www.digitalocean.com/community/tutorials/an-introduction-to-oauth-2) before returning to start.

This document covers a full integration through the following steps:

1. Register or Configure an App
2. Authenticate a User
3. Process the Response
4. Validate your Response
5. Token Use and Storage
6. Copper APIs

## 1. Register or configure an App

CopperWorks is our home for tools for developers. Every Application talking to Copper must be registered at CopperWorks. An Application is anything that talks HTTP -- for example websites and iOS Apps are called "Applications" or "Apps" to us.

You can register or configure an App at [CopperWorks](http://withcopper.com/app).

> The redirect_uri must be under your control and will be used later in this integration

Every App has a `client_id` and `client_secret`. You will need these values soon. 

The `client_secret` is your Application's key -- so **keep it confidential and secure**. We recommend you come back to Copperworks when you need it rather than storing it separately, unless you have a secure way to store it otherwise.

## 2. Authenticate a User

Authentication happens when we detect a user wants to login. This generally occurs when a person taps an Open with Copper button to initiate a log in.

> We recommend our [Open with Copper Buttons](http://withcopper.com/apps/docs/open-with-copper) to start an authentication request for a consistent user experience.

While Open with Copper Buttons are recommended, you can send users to our login dialog directly:

```
https://api.withcopper.com/oauth/dialog?client_id=CLIENT_ID&redirect_uri=REDIRECT_URI
```

These parameters are **required**:

* `client_id`: the Copper client ID of your Application
* `redirect_uri`: URI to redirect to after an attempted authorization. You must register this URI with Copperworks in advance; authorization will fail otherwise.

These parameters are _optional_:

* `response_type`: which OpenID Connect flow to use; one of:
  * `code` authorization code OAuth flow, which can be exchanged for an access token and a refresh token server-side with a client secret
  * `token` short-lived access token only, permits API requests on behalf of the user for a short period of time but will quickly expire
  * `id_token` returns an OpenID Connect ID token with basic profile data about the user, if requested 

  > `id_token` can be combined with either of the other two `response_type` values above: 
  >
  > `response_type=code id_token`
  > `response_type=token id_token`
  
* `response_mode`: redirects with tokens as query string parameters if and only if set to `query`; otherwise tokens are placed after the URL hash, inaccessible to your server
* `scope`: comma-separated list of requested permissions for user data. See [LINK TBD] for presently available scopes.
* `nonce`: if set, only allows requests that haven’t used this nonce. Prevents replay attacks, and is embedded within all access, refresh and ID tokens
* `state`: passes through as a parameter to
* `redirect_uri`: Protects against Cross-Site Request Forgery attacks; allows you to confirm that the request initiated in your app. Must be in your preregistered list of redirect_uris for the Application on CopperWorks.
* `display`: form factor of window: popup or page 

## 3. Process the Response

An Authentication Request can be approved or dismissed by both Users and Copper at different times.

Approval happens when:

1. A person confirms on their registered device
2. Copper recognizes a person is attempting to reauthenticate with an Application

Dismissal happens when:

1. The user closes the approval request on the web or in the app
2. The request expires
3. Copper believes there is a security risk

### The dialog will redirect to the `REDIRECT_URI`

> Any requested information about the transaction in the query string (see `response_mode`). 

#### Approval case

We redirect to the `REDIRECT_URI` with the requested tokens or authorization codes appended:

```
http://your.service.io/copper/callback#access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
```

#### Dismissal case

We redirect to the `REDIRECT_URI` with an error and associated error_message:

```
http://your.service.io/copper/callback#error=user_denied&error_message=The+user+denied+your+request.
```

## 4. Validate your Response

Since `REDIRECT_URI` is public, your server should proactively use the features of OAuth 2.0 to verify the messages should be trusted. 

Validating the response depends on the `response_type` you provided, and should be done before you proceed to act on the received tokens.

There are two types of responses you might need to validate: tokens and authorization codes

#### ID Token Example

If you’d asked for ID token (`response_mode=id_token`), a JWT representing the token will be appended to your redirect URI, along with the optional `state` parameter you provided.

ID Tokens are an extension to OAuth 2.0 provided by OpenID Connect. 

> Here’s a sample redirect:
> ```
> http://example.com/callback#
    id_token=eyJraWQiOiIxZTlnZGs3IiwiYWxnIjoiUlMyNTYifQ.ewogImlz
    cyI6ICJodHRwOi8vc2VydmVyLmV4YW1wbGUuY29tIiwKICJzdWIiOiAiMjQ4
    Mjg5NzYxMDAxIiwKICJhdWQiOiAiczZCaGRSa3F0MyIsCiAibm9uY2UiOiAi
    bi0wUzZfV3pBMk1qIiwKICJleHAiOiAxMzExMjgxOTcwLAogImlhdCI6IDEz
    MTEyODA5NzAsCiAibmFtZSI6ICJKYW5lIERvZSIsCiAiZ2l2ZW5fbmFtZSI6
    ICJKYW5lIiwKICJmYW1pbHlfbmFtZSI6ICJEb2UiLAogImdlbmRlciI6ICJm
    ZW1hbGUiLAogImJpcnRoZGF0ZSI6ICIwMDAwLTEwLTMxIiwKICJlbWFpbCI6
    ICJqYW5lZG9lQGV4YW1wbGUuY29tIiwKICJwaWN0dXJlIjogImh0dHA6Ly9l
    eGFtcGxlLmNvbS9qYW5lZG9lL21lLmpwZyIKfQ.rHQjEmBqn9Jre0OLykYNn
    spA10Qql2rvx4FsD00jwlB0Sym4NzpgvPKsDjn_wMkHxcp6CilPcoKrWHcip
    R2iAjzLvDNAReF97zoJqq880ZD1bwY82JDauCXELVR9O6_B0w3K-E7yM2mac
    AAgNCUwtik6SjoSUZRcf-O5lygIyLENx882p6MtmwaL1hd6qn5RZOQ0TLrOY
    u0532g9Exxcm-ChymrB4xLykpDj3lUivJt63eEGGN6DH5K6o33TcxkIjNrCD
    4XB1CKKumZvCedgHHF3IAK4dVEDSUoGlH9z4pP_eWYNXvqQOjGs-rDaQzUHl
    6cQQWNiDpWOl_lxXjQEvQ
    &state=af0ifjsldkj
 > ```

You can decode this `id_token` when many JWT libraries and at [JWT.io](http://jwt.io/) into its constituent parts: header, payload, and signature. This ID token decodes as follows:

```
{
  "iss": "http://api.withcopper.com", //issuer of this token 
  "sub": "248289761001", // id for this user, unique to your app
  "aud": "s6BhdRkqt3", //  unique id for your app 
  "nonce": "n-0S6_WzA2Mj", // nonce you provided (optionally)
  "exp": 1311281970, // expiration time for this token (unix epoch)
  "iat": 1311280970, // issued time for this token (unix epoch)
  "name": "Jane Doe", 
  "given_name": "Jane",
  "family_name": "Doe",
  "gender": "female",
  "birthdate": "0000-10-31",
  "email": "janedoe@example.com",
  "picture": "http://example.com/janedoe/me.jpg"
}
```
See [OpenID Connect reference](openid.net/specs/openid-connect-core-1_0.html) for deeper discussions of ID tokens.

Note that `scope` would need to be set to request permissions for fields like email, picture, name in the example above.

To prevent CSRF attacks, confirm that the `nonce` inside the `id_token` is equivalent to the `nonce` you requested in the initial OAuth authentication call.

#### Access Token Example

With an `access_token` (`response_type=token`), you’ll have a short-lived token for exercising our API on behalf of the given user.

##### Validating Authorization Code Flow
For the authorization code flow (`response_type=code`), send the authorization returned code to your server, pair it with your Application's `client_secret`, and exchange it for a full token over a secured server-to-server channel.

To obtain an `access_token` and `refresh_token`, make an HTTP POST to the following OAuth 2.0 endpoint:

```
POST https://api.withcopper.com/oauth/token?client_id=CLIENT_ID&grant_type=authorization_code&redirect_uri=REDIRECT_URI&client_secret=CLIENT_SECRET&code=AUTHORIZATION_CODE
```
         
These parameters are **required**:

- `client_id`: Your Application’s client id from CopperWorks
grant_type: should be set to `authorization_code`
- `redirect_uri`: The redirect_uri that you used to start the login flow
- `client_secret`: Your Application's client secret from CopperWorks. Note: never expose this secret in client-side code, whether JavaScript or mobile binaries that could be decompiled
- `code`: The authorization code received from the dialog redirect

On Success, you’ll receive a set of tokens in JSON as a response:
```
{“access_token”: ACCESS_TOKEN, “refresh_token”: REFRESH_TOKEN}                             
```

> Or an error:
> {“error”: {“message”: ERROR_MESSAGE}}

## 5. Token Use and Storage

You should store your `refresh_token` securely and use it to refresh the more volatile `access_token` as needed.

**`access_token` versus `refresh_tokens`**

All tokens are JWTs. But they have different privileges.

`access_tokens` are valid for a few hours and can be exposed directly to the web browser. All Copper API calls should be made (e.g., to /oauth/userinfo) using an `access_token`.

`refresh_tokens` are valid for 30 days. They should never be exposed directly to a browser. They should be stored securely on your server and used to periodically generate new `access_tokens`. A `refresh_token` can be used to request a new `refresh_token` before it expires.

#### Refreshing a Refresh Token
To use a `refresh_token` to obtain a new `access_token` and/or `refresh_token`, make an HTTP POST request to the following OAuth 2.0 endpoint:

```
POST https://api.withcopper.com/oauth/token
client_id=CLIENT_ID&redirect_uri=REDIRECT_URI&client_secret=CLIENT_SECRET&refresh_token=UNEXPIRED_REFRESH_TOKEN
```
These parameters are **required**:

- `client_id`: Your Application’s client id from CopperWorks
- `grant_type`: `refresh_token`
- `redirect_uri`: The `redirect_uri` that you used to start the login flow
- `client_secret`: Your Application cleint secret from CopperWorks. Note: never expose this secret in client-side code, whether JavaScript or mobile binaries that could be decompiled
- `refresh_token`: The refresh token obtained from a previous call to `/oauth/token`


# 6. Copper APIs

### [The Copper APIs](http://withcopper.com/apps)
With an `access_token` you can make calls to the Copper API on behalf of an account owner.

#### API Example

Suppose you wanted to load the profile data previously requested using scope-based permissions.

##### Request

Make an HTTP GET request to the OpenID Connect `oauth\userinfo` endpoint, passing your `access_token` in the Authorization header:

```
GET https://api.withcopper.com/oauth/userinfo 
Authorization: Bearer [access.token.jwt]        
```

The following parameters are **required**:

* HTTP Authorization header with valid `access_token`

##### Response
The `oauth\userinfo` endpoint is specified by OpenID Connect, and returns the user profile data you requested when authorizing your Application:

```
{
  “sub": "248289761001", // id for this user, unique to your app 
  "name": "Jane Doe",                                            
  "given_name": "Jane",                                          
  "family_name": "Doe",                                          
  "gender": "female",                                            
  "birthdate": "0000-10-31",                                     
  "email": "janedoe@example.com",                                
  "picture": "http://example.com/janedoe/me.jpg"                 
}
```

