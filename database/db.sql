use zabbix_updates;

create table if not exists `linha` (
  `id` int(2) NOT NULL AUTO_INCREMENT,
  `update` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `commands` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
