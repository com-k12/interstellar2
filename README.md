# Interstellar2
Средство для автоматического постинга отзывов пользователей об ваших приложениях Google Play Store в мессанджер Telegram (чат, канал, личная переписка). Приложение написано на руби и основывается на проекте [interstellar](https://github.com/meduza-corp/interstellar).

![slack](https://raw.githubusercontent.com/com-k12/interstellar2/master/telegram_screenshot.jpg)

## Как это работает
Google Play [экспортирует](https://support.google.com/googleplay/android-developer/answer/138230) все отзывы на ваши приложения один раз в день в [Google Cloud Storage](https://cloud.google.com/storage/docs) bucket.

_Interstellar2_ скачивает отзывы с помощью утилиты [gsutil](https://cloud.google.com/storage/docs/gsutil) и постит каждый отзыв в канал Телеграма с помощью [бота](https://core.telegram.org/bots/api#sendmessage).

Всё это запускается с помощью cron раз в день.

## Настройка

1. Создать фаил `secrets/secrets.yml`. Пример можно посмотреть в `secrets/secrets.yml.example`.

  Вам необходимо указать:
  - Bucket id (app_repo). Можно найти на странице Reviews в консоле разработчика Google Play. Вида:  `pubsite_prod_rev_01234567890987654321`
  - Сформировать telegram_url для [метода отправки](https://core.telegram.org/bots/api#sendmessage) сообщения в телеграм через вашего бота
  - Указать telegram_chat_id. Это айди группового чата/канала или личной переписки с ботом

2. Сконфигурировать [gsutil](https://github.com/GoogleCloudPlatform/gsutil/). Простое питоновское приложение от Google, инструкция далее.

3. Установить `gem install rest-client`

### Настройка gsutil
1. Запустите `gsutil/gsutil config` и следуйте по шагам.
2. Программа создаст .boto фаил в вашей домашней дирректории.
3. Скопируйте этот фаил в папку ./secrets.

Вы всегда можете установить последнюю версию gsutil(https://cloud.google.com/storage/docs/gsutil_install) и изменить следующую строку в файле `sender.rb`
`system "BOTO_PATH=./secrets/.boto gsutil/gsutil cp -r gs://#{CONFIG["app_repo"]}/reviews/#{csv_file_name} . > log.log 2>&1"`
Только обратите внимание, что `sender.rb` ожидает фаил ревью csv в той же папке где и находится сам.

## Использование
Один раз сконфигурировать и запускать `PKGNAME=com.example.app ruby sender.rb`, где PKGNAME системная переменная которая содержит имя вашего пакета (приложения)

## Использование через докер
Для того чтоб не быть зависимым от руби, можно использовать готовый официальный образ руби и запускать следующим образом.

    docker run --rm -e "PKGNAME=com.exampe.app" -v $(pwd):/interstellar2 ruby:latest sh -c "gem install rest-client 1>/dev/null 2>&1; cd /interstellar2; ruby ./sender.rb"

Команду запускать из корневой папки.

## License
[This piece of software is distributed under 2-clause BSD license.
Well, actually, you code it yourself during the coffee-break.](https://github.com/meduza-corp/interstellar)
