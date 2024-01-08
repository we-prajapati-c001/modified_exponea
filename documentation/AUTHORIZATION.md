## Authorization

Data between SDK and BE are delivered trough authorized HTTP/HTTPS communication. Level of security has to be defined by developer.
All authorization modes are used to set `Authorization` HTTP/HTTPS header.

### Token authorization

This mode is required and has to be set by `authorization` parameter in `ExponeaConfiguration`. See [configuration](./CONFIGURATION.md).

Token authorization mode has to be given in `Token <value>` format. It is used for all public API access by default:

* `POST /track/v2/projects/<projectToken>/customers` as tracking of customer data
* `POST /track/v2/projects/<projectToken>/customers/events` as tracking of event data
* `POST /track/v2/projects/<projectToken>/campaigns/clicks` as tracking campaign events
* `POST /data/v2/projects/<projectToken>/customers/attributes` as fetching customer attributes
* `POST /data/v2/projects/<projectToken>/consent/categories` as fetching consents
* `POST /webxp/s/<projectToken>/inappmessages?v=1` as fetching InApp messages
* `POST /webxp/projects/<projectToken>/appinbox/fetch` as fetching of AppInbox data
* `POST /webxp/projects/<projectToken>/appinbox/markasread` as marking of AppInbox message as read
* `POST /campaigns/send-self-check-notification?project_id=<projectToken>` as part of SelfCheck push notification flow

Please check more details about [Public API](https://documentation.bloomreach.com/engagement/reference/authentication#public-api-access).

``` dart
final _plugin = ExponeaPlugin();
...
final config = ExponeaConfiguration(
    ...
    authorizationToken: "Token yourPublicApiTokenAbc123",
    ...
);
final configured = await _plugin.configure(config);
```

> There is no change nor migration needed in case of using of `authorization` parameter if you are already using SDK in your app.

### Customer Token authorization

JSON Web Tokens are an open, industry standard [RFC 7519](https://tools.ietf.org/html/rfc7519) method for representing claims securely between SDK and BE. We recommend this method to be used according to higher security.

This mode is optional and may be set by `advancedAuthEnabled` parameter in `ExponeaConfiguration`. See [configuration](./CONFIGURATION.md).

Authorization value is used in `Bearer <value>` format. Currently, it is supported for listed API (for others Token authorization is used when `advancedAuthEnabled = true`):

* `POST /webxp/projects/<projectToken>/appinbox/fetch` as fetching of AppInbox data
* `POST /webxp/projects/<projectToken>/appinbox/markasread` as marking of AppInbox message as read

To activate this mode you need to set `advancedAuthEnabled` parameter `true` in `ExponeaConfiguration` as in given example:

``` typescript
final _plugin = ExponeaPlugin();
...
final config = ExponeaConfiguration(
    ...
    advancedAuthEnabled: true,
    ...
);
final configured = await _plugin.configure(config);
```

Then an implementation of Authorization provider is needed. Provider has to be written in native code and differently for each platform.

### Android authorization provider

First step is to implement an interface of `com.exponea.sdk.services.AuthorizationProvider` as in given example:

```kotlin
class ExampleAuthProvider : AuthorizationProvider {

    override fun getAuthorizationToken(): String? {
        return "eyJ0eXAiOiJKV1Q..."
    }
}
```

Final step is to register your AuthorizationProvider to AndroidManifest.xml file as:

```xml
<application
    ...
    <meta-data
        android:name="ExponeaAuthProvider"
        android:value="com.your.app.security.ExampleAuthProvider"
        />
</application>
```

If you define AuthorizationProvider but is not working correctly, SDK initialization will fail. Please check for logs.
1. If you enable Customer Token authorization by configuration flag `advancedAuthEnabled` and implementation has not been found, you'll see log
`Advanced auth has been enabled but provider has not been found`
2. If you register class in AndroidManifest.xml but it cannot been found, you'll see log
`Registered <your class> class has not been found` with detailed info.
3. If you register class in AndroidManifest.xml but it is not implementing auth interface, you will see log
`Registered <your class> class has to implement com.exponea.sdk.services.AuthorizationProvider`

AuthorizationProvider is loaded while SDK is initializing or after `ExponeaPlugin().anonymize()` is called; so you're able to see these logs in that time in case of any problem.

### iOS authorization provider

Single step is to implement a protocol of `AuthorizationProviderType` with @objc attribute as in given example:

```swift
@objc(ExponeaAuthProvider)
public class ExampleAuthProvider: NSObject, AuthorizationProviderType {
    required public override init() { }
    public func getAuthorizationToken() -> String? {
        "YOUR JWT TOKEN"
    }
}
```

#### Asynchronous implementation of AuthorizationProvider

Token value is requested for every HTTP call in runtime. Method `getAuthorizationToken()` is written for synchronously usage but is invoked in background thread. Therefore, you are able to block any asynchronous token retrieval (i.e. other HTTP call) and waits for result by blocking this thread. In case of error result of your token retrieval you may return NULL value but request will automatically fail.

As example for Android:

```kotlin
class ExampleAuthProvider : AuthorizationProvider {
    override fun getAuthorizationToken(): String? = runBlocking {
        return@runBlocking suspendCoroutine { done ->
            retrieveTokenAsync(
                    success = {token -> done.resume(token)},
                    error = {error -> done.resume(null)}
            )
        }
    }
}
```

As example for iOS:

```swift
@objc(ExponeaAuthProvider)
public class ExampleAuthProvider: NSObject, AuthorizationProviderType {
    required public override init() { }
    public func getAuthorizationToken() -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var token: String?
        let task = yourAuthTokenReqUrl.dataTask(with: request) {
            token = $0
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return token
    }
}
```

> Multiple network libraries are supporting a different approaches (coroutines, Promises, Rx, etc...) but principle stays same - feel free to block invocation of `getAuthorizationToken` method.

#### Customer Token retrieval policy

Token value is requested for every HTTP call (listed previously in this doc) that requires it.
As it is common thing that JWT tokens have own expiration lifetime so may be used multiple times. Thus information cannot be read from JWT token value directly so SDK is not storing token in any cache. As developer, you may implement any type of token cache behavior you want.

As example for Android:

```kotlin
class ExampleAuthProvider : AuthorizationProvider {

    private var tokenCache: String? = null

    override fun getAuthorizationToken(): String? = runBlocking {
         if (tokenCache.isNullOrEmpty()) {
             tokenCache = suspendCoroutine { done ->
                 retrieveTokenAsync(
                     success = {token -> done.resume(token)},
                     error = {error -> done.resume(null)}
                 )
             }
         }
         return@runBlocking tokenCache
     }
}
```

As example or iOS:

```swift
@objc(ExponeaAuthProvider)
public class ExampleAuthProvider: NSObject, AuthorizationProviderType {
    required public override init() { }

    private var tokenCache: String?
    private var lifetime: Double?

    public func getAuthorizationToken() -> String? {
        if tokenCache == nil || hasExpired(lifetime) {
            (tokenCache, lifetime) = loadJwtToken()
        }
        return tokenCache
    }

    private func loadJwtToken() -> String? {
        ...
    }
}
```

> Please consider to store your cached token in more secured way. Android offers you multiple options such as using [KeyStore](https://developer.android.com/training/articles/keystore) or use [Encrypted Shared Preferences](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences), for iOS try to use [Keychain](https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/storing_keys_in_the_keychain) or use [CryptoKit](https://developer.apple.com/documentation/cryptokit/)

> :warning: Customer Token is valid until its expiration and is assigned to current customer IDs. Bear in mind that if customer IDs have changed (during `identifyCustomer` or `anonymize` method) your Customer token is invalid for future HTTP requests invoked for new customer IDs.
