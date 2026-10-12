// Full AZ / RU / EN coverage. No codegen — production-simple.
class L10n {
  final String lang;
  const L10n(this.lang);

  static const _v = <String, Map<String, String>>{
    'appName': {'az': 'YoldaşMoto', 'ru': 'YoldashMoto', 'en': 'YoldashMoto'},
    'tagline': {'az': 'Yolda heç kim tək qalmır', 'ru': 'Никто не останется один на дороге', 'en': 'Nobody gets left alone on the road'},
    'sos': {'az': 'SOS', 'ru': 'SOS', 'en': 'SOS'},
    'callMechanic': {'az': 'Usta çağır', 'ru': 'Вызвать механика', 'en': 'Call a mechanic'},
    'map': {'az': 'Xəritə', 'ru': 'Карта', 'en': 'Map'},
    'mechanics': {'az': 'Ustalar', 'ru': 'Механики', 'en': 'Mechanics'},
    'tow': {'az': 'Evakuator', 'ru': 'Эвакуаторы', 'en': 'Tow'},
    'market': {'az': 'Bazar', 'ru': 'Маркет', 'en': 'Market'},
    'history': {'az': 'Tarixçə', 'ru': 'История', 'en': 'History'},
    'profile': {'az': 'Profil', 'ru': 'Профиль', 'en': 'Profile'},
    'admin': {'az': 'Admin', 'ru': 'Админ', 'en': 'Admin'},
    'garage': {'az': 'Qarajım', 'ru': 'Мой гараж', 'en': 'My garage'},
    'online': {'az': 'Onlayn', 'ru': 'Онлайн', 'en': 'Online'},
    'offline': {'az': 'Oflayn', 'ru': 'Офлайн', 'en': 'Offline'},
    'imComing': {'az': 'Gəlirəm', 'ru': 'Я еду', 'en': "I'm coming"},
    'imOk': {'az': 'Yaxşıyam', 'ru': 'Я в порядке', 'en': "I'm OK"},
    'falseAlarm': {'az': 'Yalan həyəcan', 'ru': 'Ложная тревога', 'en': 'False alarm'},
    'problemSolved': {'az': 'Problem həll olundu', 'ru': 'Проблема решена', 'en': 'Problem solved'},
    'cancel': {'az': 'Ləğv et', 'ru': 'Отмена', 'en': 'Cancel'},
    'save': {'az': 'Yadda saxla', 'ru': 'Сохранить', 'en': 'Save'},
    'call': {'az': 'Zəng', 'ru': 'Позвонить', 'en': 'Call'},
    'navigate': {'az': 'Get', 'ru': 'Маршрут', 'en': 'Navigate'},
    'accept': {'az': 'Qəbul et', 'ru': 'Принять', 'en': 'Accept'},
    'decline': {'az': 'Rədd et', 'ru': 'Отклонить', 'en': 'Decline'},
    'search': {'az': 'Axtar', 'ru': 'Поиск', 'en': 'Search'},
    'login': {'az': 'Daxil ol', 'ru': 'Войти', 'en': 'Log in'},
    'signup': {'az': 'Qeydiyyat', 'ru': 'Регистрация', 'en': 'Sign up'},
    'sendSos': {'az': 'SOS göndər', 'ru': 'Отправить SOS', 'en': 'Send SOS'},
    'noOneNearby': {'az': 'Yaxınlıqda heç kim yoxdur — kataloqu açın', 'ru': 'Рядом никого нет — откройте справочник', 'en': 'Nobody nearby — open the directory'},
    'crashTitle': {'az': 'Qəza aşkarlandı?', 'ru': 'Обнаружено падение?', 'en': 'Crash detected?'},
    'availableNow': {'az': 'Hazırda aktivdir', 'ru': 'Доступен сейчас', 'en': 'Available now'},
    'verifyQueue': {'az': 'Təsdiq növbəsi', 'ru': 'Очередь проверки', 'en': 'Verification queue'},
    'name': {'az': 'Ad', 'ru': 'Имя', 'en': 'Name'},
    'phone': {'az': 'Telefon', 'ru': 'Телефон', 'en': 'Phone'},
    'smsCode': {'az': 'SMS kodu', 'ru': 'SMS-код', 'en': 'SMS code'},
    'sendCode': {'az': 'Kod göndər', 'ru': 'Отправить код', 'en': 'Send code'},
    'ridingType': {'az': 'Sürüş tipi', 'ru': 'Тип езды', 'en': 'Riding type'},
    'terms': {'az': 'Şərtlər və məxfilik', 'ru': 'Условия и конфиденциальность', 'en': 'Terms & privacy'},
    'agreeTerms': {'az': 'Şərtlərlə razıyam', 'ru': 'Согласен с условиями', 'en': 'I agree to terms'},
    'myListings': {'az': 'Elanlarım', 'ru': 'Мои объявления', 'en': 'My listings'},
    'favorites': {'az': 'Sevimlilər', 'ru': 'Избранное', 'en': 'Favorites'},
    'report': {'az': 'Şikayət', 'ru': 'Пожаловаться', 'en': 'Report'},
    'emergency': {'az': 'Təcili: 112 / 103', 'ru': 'Экстренно: 112 / 103', 'en': 'Emergency: 112 / 103'},
    'emergencyContacts': {'az': 'Təcili kontaktlar', 'ru': 'Экстренные контакты', 'en': 'Emergency contacts'},
    'notifs': {'az': 'Bildirişlər', 'ru': 'Уведомления', 'en': 'Notifications'},
    'deleteAccount': {'az': 'Hesabı sil', 'ru': 'Удалить аккаунт', 'en': 'Delete account'},
    'logout': {'az': 'Çıxış', 'ru': 'Выйти', 'en': 'Log out'},
    'addBike': {'az': '+ Moto əlavə', 'ru': '+ Добавить мото', 'en': '+ Add bike'},
    'addPhoto': {'az': 'Foto əlavə', 'ru': 'Добавить фото', 'en': 'Add photo'},
    'comment': {'az': 'Şərh / oriyentir…', 'ru': 'Комментарий / ориентир…', 'en': 'Comment / landmark…'},
    'canMove': {'az': 'Moto hərəkət edə bilir?', 'ru': 'Мото на ходу?', 'en': 'Can the bike move?'},
    'newListing': {'az': 'Yeni elan', 'ru': 'Новое объявление', 'en': 'New listing'},
    'inspection': {'az': 'Usta yoxlanışı sifariş et', 'ru': 'Заказать проверку механиком', 'en': 'Order mechanic inspection'},
    'callSeller': {'az': 'Satıcıya zəng', 'ru': 'Позвонить продавцу', 'en': 'Call seller'},
    'becomeMechanic': {'az': 'Usta ol', 'ru': 'Стать механиком', 'en': 'Become mechanic'},
    'becomeTow': {'az': 'Evakuator ol', 'ru': 'Стать эвакуатором', 'en': 'Become tow operator'},
    'priceLines': {'az': 'Qiymət sətirləri', 'ru': 'Строки цен', 'en': 'Price lines'},
    'workingHours': {'az': 'İş saatları', 'ru': 'Часы работы', 'en': 'Working hours'},
    'alreadyTaken': {'az': 'Artıq götürülüb', 'ru': 'Уже занято', 'en': 'Already taken'},
    'retry': {'az': 'Yenidən cəhd', 'ru': 'Повторить', 'en': 'Retry'},
    'widen': {'az': 'Radiusu genişləndir', 'ru': 'Расширить радиус', 'en': 'Widen radius'},
    'receipt': {'az': 'Qəbz', 'ru': 'Чек', 'en': 'Receipt'},
    'whereTo': {'az': 'Hara gedirsən?', 'ru': 'Куда едем?', 'en': 'Where to?'},
    'nearby': {'az': 'Yaxınlıqda', 'ru': 'Рядом', 'en': 'Nearby'},
    'eta': {'az': 'Çatış', 'ru': 'Прибытие', 'en': 'ETA'},
  };

  String t(String key) => _v[key]?[lang] ?? _v[key]?['en'] ?? key;

  static const problems = [
    ('chain', {'az': 'Zəncir qırıldı', 'ru': 'Порвалась цепь', 'en': 'Broken chain'}),
    ('fuel', {'az': 'Yanacaq bitdi', 'ru': 'Кончился бензин', 'en': 'Out of fuel'}),
    ('cable', {'az': 'Tros qırıldı', 'ru': 'Порвался трос', 'en': 'Broken cable'}),
    ('tire', {'az': 'Təkər partladı', 'ru': 'Пробито колесо', 'en': 'Flat tire'}),
    ('start', {'az': 'İşə düşmür', 'ru': 'Не заводится', 'en': "Won't start"}),
    ('battery', {'az': 'Akkumulyator', 'ru': 'Аккумулятор', 'en': 'Dead battery'}),
    ('brake', {'az': 'Əyləc', 'ru': 'Тормоза', 'en': 'Brake problem'}),
    ('overheat', {'az': 'Qızma', 'ru': 'Перегрев', 'en': 'Overheating'}),
    ('engine', {'az': 'Mühərrik', 'ru': 'Двигатель', 'en': 'Engine'}),
    ('accident', {'az': 'Qəza', 'ru': 'Авария', 'en': 'Accident'}),
    ('other', {'az': 'Digər', 'ru': 'Другое', 'en': 'Other'}),
  ];

  String problemName(String id) {
    final e = problems.where((p) => p.$1 == id);
    if (e.isEmpty) return id;
    return e.first.$2[lang] ?? e.first.$2['en']!;
  }
}
