# "My Runshaw" App

| Android | iOS |
|:-:|:-:|
| [<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="50">](https://play.google.com/store/apps/details?id=com.daniel.runshaw&hl=en_GB) | [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="50">](https://apps.apple.com/gb/app/my-runshaw/id6739817271) |


This is an unofficial app allowing students to share timetables with each other to see who is free, it provides bus push notifications and calculates bus bay locations, and it shows a map of the college and its layout. Backend source is available in a [separate repository](https://github.com/Dragon863/myrunshaw-backend). After this gained thousands of users in a few months, building this app has taught me a lot about scaling projects and maintaining production applications.

## Development

I have written a post [on my website](https://danieldb.uk/posts/runshaw-app/) if you're interested in learning how I created this app.
The key components include:
- Flutter frontend
- FastAPI backend
- Postgres database
- Appwrite auth
- ~~Aptabase analytics~~ Now migrated to Posthog
- Docker image based deployments
- OneSignal push notifications

## Screenshots

| | |
|-|-|
|![Main Screen](.images/screenshot_1.png) | ![Bus Page](.images/screenshot_2.png)|
|![Pay page](.images/screenshot_3.png) |![Timetable page](.images/screenshot_4.png)|
|![Map page](.images/screenshot_5.png) | |

## Disclaimer

> This application is not affiliated with nor is it endorsed by any educational institution. Its development is solely maintained by a student, and the developer is not liable for any damages connected with the use of this application.