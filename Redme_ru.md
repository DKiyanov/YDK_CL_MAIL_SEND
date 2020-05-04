## SAP ABAP отправка почты
Стандартный в SAP набор классов для отправки почты BCS, очень не удобен в использовнии, в нём есть ряд проблем решаемых весьма не красивыми способами.
Поэтому я написал один простой класс объёртку, работать с которым просто и приятно.
Думаю в каких то особо сложных случаях может потребоваться использовать стандарный BCS, но в обсалютном большинстве случаев моего класса вполне достаточно.

Для установки этого на SAP сервер используйте [abapGit](https://docs.abapgit.org/)

Класс YDK_CL_MAIL_SEND  
основные методы:
* CONSTRUCTOR - создаёт инстанцию класса (экземпляр письма)                                              
* ADD_ATTACHMENT - добаление вложения в письмо
* ADD_RECIPIENT	- добавление получателей в письмо
* SEND - отправка письма

через атрибуты класса остаётся доступ к соответствующим объектам BCS  
атрибуты:
* SEND_REQUEST Type Ref To CL_BCS
* DOCUMENT Type Ref To CL_DOCUMENT_BCS

**Пример использования:**
```ABAP
  DATA: lo_mls TYPE REF TO ydk_cl_mail_send.

  CREATE OBJECT lo_mls
    EXPORTING
      subject   = subject
      body_type = ydk_cl_mail_send=>cbody_type-html
      body      = body.

  lo_mls->add_recipient( recipient_mail = 'anyuser@somewhere.com' ).
  
  lo_mls->send( send_immediately = abap_true ).
```