# EXPLANATION.md

## 1. What was the bug?

When `oauth2Token` was set to a plain object (i.e. `Record<string, unknown>`
instead of an `OAuth2Token` instance), the client skipped the refresh and never
set an `Authorization` header on API requests.

## 2. Why did it happen?

The refresh guard used a combined truthiness + `instanceof` check:

```typescript
if (
  !this.oauth2Token ||
  (this.oauth2Token instanceof OAuth2Token && this.oauth2Token.expired)
)
```

A plain object is truthy, so `!this.oauth2Token` is `false`. The second branch
only evaluates `.expired` when the token is an `OAuth2Token` instance — so a
plain object silently passed through both conditions without triggering a
refresh.

## 3. Why does your fix solve it?

Adding `!(this.oauth2Token instanceof OAuth2Token)` as an explicit middle
condition catches any value that is neither `null` nor a proper `OAuth2Token`
instance and forces a refresh:

```typescript
if (
  !this.oauth2Token ||
  !(this.oauth2Token instanceof OAuth2Token) ||
  this.oauth2Token.expired
)
```

## 4. One realistic edge case the tests still don't cover

A race condition happens when two request() calls run at the same time, both 
notice the token has expired, and both try to refresh it at once. One refresh 
ends up overwriting the other, which can cause one request to use the wrong 
(or no longer valid) token.