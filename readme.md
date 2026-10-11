# Russian Trusted CA Remover

A lightweight PowerShell utility for Windows 10/11 that detects, backs up, and removes Russian Trusted Root CA and Russian Trusted Sub CA certificates issued by the Russian Ministry of Digital Development.

No third-party dependencies. No additional software required.

**Languages:** [English](#english) | [Русский](#русский)

---

## English

### Features

- **Automatic detection** — finds Russian Trusted CA certificates in Windows certificate stores.
- **System-wide cleanup** — checks both the current user and local machine stores.
- **Backup before deletion** — exports matching certificates as `.cer` files.
- **Confirmation required** — no certificates are removed without your approval.
- **Detailed output** — displays certificate subjects, SHA-1 thumbprints, and removal results.
- **No external dependencies** — works with built-in Windows PowerShell tools.

### Supported certificates

The utility targets certificates with matching Common Names (CN), including:

- `Russian Trusted Root CA`
- `Russian Trusted Sub CA`

Multiple versions of matching certificates can be detected.

### Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1
- Administrator privileges

### Installation and usage

**1. Download**

Download the latest archive from the repository's [Releases](../../releases) page, or clone the repository:

```bash
git clone https://github.com/VitoCrow/russian-trusted-ca-remover.git
```

**2. Run**

Extract the archive and double-click:

`START_CLEANUP.cmd`

Approve the Windows User Account Control (UAC) prompt.

**3. Review**

The utility scans Windows certificate stores and displays the matching certificates, including their subjects and SHA-1 thumbprints.

**4. Confirm deletion**

Type:

```text
DELETE
```

Press Enter to confirm. Any other input cancels the operation.

**5. Restart**

After cleanup, restart your browsers. Reboot Windows if necessary.

### Backups and reports

Before deleting matching certificates, the utility creates backups and saves a cleanup report.

The backup directory follows this format:

```text
C:\Users\<username>\Russian_CA_Cleanup_YYYYMMDD_HHMMSS
```

Keep these files if you may need to restore the certificates later.

### Firefox support

Firefox may maintain its own certificate store. Certificates imported directly into Firefox are **not removed** by this utility.

To remove them manually:

1. Open Firefox.
2. Navigate to `about:preferences#privacy`.
3. Find the certificate management settings.
4. Open **View Certificates → Authorities**.
5. Locate the Russian Trusted CA certificates.
6. Select the appropriate entries and choose **Delete or Distrust**.
7. Restart Firefox.

### Security notice

**Review certificates carefully before confirming deletion.**

The utility identifies matching certificates by their names and does not provide a guarantee that every certificate was originally installed from a particular website.

Removing trusted certificates may cause websites that depend on them to display HTTPS certificate errors.

The utility does not remove certificates from other Windows user profiles, browser-specific stores, or every possible system trust source.

### License

This project is distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## Русский

### О проекте

**Russian Trusted CA Remover** — небольшая PowerShell-утилита для Windows 10/11, предназначенная для поиска, резервного копирования и удаления корневых и промежуточных сертификатов Минцифры России.

Программа не требует установки дополнительных зависимостей.

### Возможности

- **Автоматический поиск** сертификатов Russian Trusted CA.
- **Проверка системы и пользователя** — анализ хранилищ текущего пользователя и всего компьютера.
- **Резервное копирование** сертификатов перед удалением.
- **Подтверждение операции** — удаление выполняется только после согласия пользователя.
- **Подробный отчёт** с названиями, SHA-1 отпечатками и результатами удаления.
- **Работа без сторонних программ** — используются встроенные средства Windows.

### Какие сертификаты удаляются

Утилита ищет сертификаты с подходящими Common Name (CN):

- `Russian Trusted Root CA`
- `Russian Trusted Sub CA`

Поддерживается поиск нескольких версий этих сертификатов.

### Системные требования

- Windows 10 или Windows 11
- Windows PowerShell 5.1
- Права администратора

### Инструкция по использованию

**1. Скачайте архив**

Загрузите последнюю версию из раздела [Releases](../../releases) или клонируйте репозиторий.

**2. Запустите программу**

Распакуйте архив и откройте:

`START_CLEANUP.cmd`

Подтвердите запрос контроля учётных записей Windows (UAC).

**3. Проверьте результаты поиска**

Скрипт покажет обнаруженные сертификаты, названия и их SHA-1 отпечатки.

**4. Подтвердите удаление**

Введите `DELETE` и нажмите Enter.

Любой другой ввод отменяет операцию.

**5. Перезагрузите браузеры**

После завершения рекомендуется перезапустить браузеры, а при необходимости — Windows.

### Резервные копии

Перед удалением программа сохраняет резервные копии сертификатов в формате `.cer` и отчёт о выполнении операции.

Пример расположения:

```text
C:\Users\<имя_пользователя>\Russian_CA_Cleanup_YYYYMMDD_HHMMSS
```

Не удаляйте резервные копии, если в дальнейшем может потребоваться восстановление доверия к сертификатам.

### Firefox

Firefox может использовать собственное хранилище сертификатов.

Для ручного удаления:

1. Откройте `about:preferences#privacy`.
2. Перейдите к управлению сертификатами.
3. Откройте вкладку **Центры сертификации**.
4. Найдите сертификаты `Russian Trusted Root CA` и `Russian Trusted Sub CA`.
5. Удалите соответствующие сертификаты или отключите доверие к ним.
6. Перезапустите браузер.

**Важно:** утилита не очищает отдельное хранилище Firefox автоматически.

### Предупреждение

Удаление доверенных сертификатов может привести к ошибкам HTTPS на некоторых сайтах.

Программа определяет сертификаты по их названиям, поэтому перед подтверждением операции рекомендуется внимательно проверять найденные записи.

Скрипт не гарантирует удаление сертификатов из других профилей Windows или всех возможных хранилищ браузеров.

### Лицензия

Проект распространяется по лицензии **MIT**. Подробности в файле [LICENSE](LICENSE).
