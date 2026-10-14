# YOGI — Agent 안내

## Cursor Cloud specific instructions

### 화면 미리보기 (밖에서 폰으로 볼 때)

1. Flutter 웹이 `:8080`에서 돌아가는지 확인  
   (`terminals`의 `flutter-web` 또는 직접 실행)
   ```bash
   cd front && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```

2. **Cursor Forwarded Ports**로 8080을 열면 PC/Agents Window에서 미리보기 가능.

3. **폰에서 URL로 보려면** cloudflared 임시 터널:
   ```bash
   cloudflared tunnel --url http://127.0.0.1:8080
   ```
   출력에 나오는 `https://xxxx.trycloudflare.com` 주소를 사용자에게 알려줄 것.

### 주의

- 터널 URL은 세션마다 바뀜. Agent/터널이 꺼지면 접속 불가.
- iOS 네이티브 빌드는 Cloud VM에서 하지 말 것 (Mac/Xcode 필요). 웹으로만 확인.
- back(Spring)은 필요할 때만 `cd back && ./mvnw spring-boot:run`.

## 로컬 (집 Windows PC)

```powershell
cd C:\YOGI\front
flutter run -d chrome
```

집 PC를 켜둔 채 밖에서 보려면:

```powershell
.\scripts\preview-tunnel.ps1
```
