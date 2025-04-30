# GitHub Repo Kurulum ve SEO Rehberi

Bu rehber, KeyboardBlocker projenizi GitHub'a yükleme ve arama motorlarında daha iyi görünmesi için optimize etme adımlarını içerir.

## 1. GitHub Repo Oluşturma

1. [GitHub](https://github.com) hesabınıza giriş yapın
2. Sağ üst köşedeki "+" ikonuna tıklayıp "New repository" seçin
3. Repository adını "macos-keyboardblocker" olarak girin
4. Açıklama ekleyin: "A macOS utility to temporarily lock your keyboard for cleaning"
5. "Public" seçeneğini işaretleyin
6. "Initialize this repository with a README" seçeneğini işaretlemeyin (zaten bir README oluşturduk)
7. "Create repository" düğmesine tıklayın

## 2. Projeyi Yükleme

Aşağıdaki komutları terminal üzerinden çalıştırın:

```bash
# Yerel git deposunu başlat
git init

# Tüm değişiklikleri ekle
git add .

# İlk commit'i oluştur
git commit -m "Initial commit: macOS Keyboard Blocker app"

# GitHub uzak depoyu ekle (GitHub kullanıcı adınızı girin)
git remote add origin https://github.com/KULLANICI_ADINIZ/macos-keyboardblocker.git

# Değişiklikleri GitHub'a gönder
git push -u origin main
```

## 3. GitHub SEO Optimizasyonu

### About Bölümü

GitHub repo sayfanızın sağ tarafındaki "About" bölümünü düzenleyin:

1. Kısa bir açıklama ekleyin: "🔒 Lock your Mac's keyboard while cleaning - prevents accidental keypresses"
2. Website olarak şirket sitenizi ekleyin: "https://codev.com.tr"
3. Konular (Topics) ekleyin (aşağıda listelenmiştir)

### Topics (Konular)

GitHub repo sayfanızın sağ üst tarafındaki dişli simgesine tıklayarak veya "About" bölümünden "Manage topics" diyerek şu konuları ekleyin:

```
macos
keyboard
keyboard-cleaner
keyboard-lock
utility
swift
swiftui
clean-code
productivity
mac-app
apple-silicon
intel-mac
```

### GitHub Sürümleri (Releases)

1. GitHub repo sayfanızda "Releases" bölümüne gidin
2. "Draft a new release" düğmesine tıklayın
3. "Choose a tag" alanına "v1.0.0" yazın ve "Create new tag" seçin
4. Sürüm başlığı olarak "KeyboardBlocker v1.0.0" girin
5. Sürüm notlarına şunu yazın:

```markdown
# KeyboardBlocker v1.0.0

Initial release of KeyboardBlocker, a macOS utility that lets you safely clean your keyboard without triggering unwanted actions.

## Features
- Temporarily blocks all keyboard input
- Works across all connected monitors
- Easy unlock with the ESC key
- Modern macOS native design
- Privacy focused - no data collection

## Installation
1. Download the zip file
2. Extract KeyboardBlocker.app
3. Move to your Applications folder
4. Control+click and select "Open" when first launching

## Requirements
- macOS 11 (Big Sur) or later
- Compatible with Apple Silicon and Intel Macs
```

6. Dist klasöründeki `KeyboardBlocker.app.zip` dosyasını sürüt bırak yöntemiyle veya "Attach binaries" alanından yükleyin
7. "Publish release" düğmesine tıklayın

## 4. README Ekran Görüntüsü

Repo'nuzda `screenshot.png` dosyasının olduğundan emin olun. Eğer yoksa:

1. Uygulamanızın güzel bir ekran görüntüsünü alın
2. `screenshot.png` olarak adlandırın ve projenin kök dizinine kaydedin
3. Şu komutları kullanarak GitHub'a yükleyin:

```bash
git add screenshot.png
git commit -m "Add application screenshot"
git push
```

## 5. Sosyal Paylaşım

GitHub projenize daha fazla trafik çekmek için:

1. Sosyal medya (Twitter, LinkedIn, vb.) üzerinde projenizi paylaşın
2. İlgili Mac ve geliştirici forumlarında (Reddit r/mac, r/macapps, r/swift vb.) projenizden bahsedin
3. Hacker News, Dev.to gibi geliştirici platformlarında Show HN/Show Dev tarzı paylaşımlar yapın

Bu adımları tamamladıktan sonra, GitHub reponuz hem kullanıcılar hem de arama motorları için daha görünür olacaktır. 