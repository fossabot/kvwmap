/*!40000 ALTER TABLE `stelle` DISABLE KEYS */;
INSERT INTO `stelle` (`Bezeichnung`, `Bezeichnung_low-german`, `Bezeichnung_english`, `Bezeichnung_polish`, `Bezeichnung_vietnamese`, `start`, `stop`, `minxmax`, `minymax`, `maxxmax`, `maxymax`, `epsg_code`, `Referenzkarte_ID`, `Authentifizierung`, `ALB_status`, `wappen`, `wappen_link`, `alb_raumbezug`, `alb_raumbezug_wert`, `logconsume`, `pgdbhost`, `pgdbname`, `pgdbuser`, `pgdbpasswd`, `ows_title`, `wms_accessconstraints`, `ows_abstract`, `ows_contactperson`, `ows_contactorganization`, `ows_contactemailaddress`, `ows_contactposition`, `ows_fees`, `ows_srs`, `check_client_ip`, `check_password_age`, `allowed_password_age`, `use_layer_aliases`, `selectable_layer_params`, `hist_timestamp`, `default_user_id`) VALUES
	('Administration', NULL, NULL, NULL, NULL, '0000-00-00', '0000-00-00', 201165, 5867815, 477900, 6081468, '25833', 1, '1', '30', 'Logo_GDI-Service_200x47.png', '', '', '', NULL, 'localhost', '', '', '', '', '', '', '', '', '', '', '', '', '0', '0', 6, '0', NULL, 0, NULL),
	('Dateneingeber', NULL, NULL, NULL, NULL, '0000-00-00', '0000-00-00', 201165, 5867815, 477900, 6081468, '35833', 1, '1', '30', 'logo_lung.jpg', '', '', '', NULL, 'localhost', '', '', '', '', '', '', '', '', '', '', '', '', '0', '0', 6, '0', NULL, 0, NULL),
	('Entscheider', NULL, NULL, NULL, NULL, '0000-00-00', '0000-00-00', 201165, 5867815, 477900, 6081468, '35833', 1, '1', '30', 'logo_lung.jpg', '', '', '', NULL, 'localhost', '', '', '', '', '', '', '', '', '', '', '', '', '0', '0', 6, '0', NULL, 0, NULL);
/*!40000 ALTER TABLE `stelle` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;