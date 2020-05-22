class YDK_CL_MAIL_SEND definition
  public
  final
  create public .

public section.

  types:
    ty_uid_tab TYPE STANDARD TABLE OF twb_uname  WITH DEFAULT KEY .
  types:
    ty_email_tab TYPE STANDARD TABLE OF adr6-smtp_addr WITH DEFAULT KEY .

  data SEND_REQUEST type ref to CL_BCS .
  data DOCUMENT type ref to CL_DOCUMENT_BCS .
  constants:
    BEGIN OF cemail_by_uid,
        detect_email_by_uid_and_send TYPE c LENGTH 1 VALUE 'X',
        send_both_by_uid_and_email   TYPE c LENGTH 1 VALUE 'Y',
      END   OF cemail_by_uid .
  constants:
    BEGIN OF cbody_type,
                 text TYPE so_obj_tp VALUE 'TXT',
                 html TYPE so_obj_tp VALUE 'HTM',
               END   OF cbody_type .

  methods CONSTRUCTOR
    importing
      !SUBJECT type STRING
      !BODY_TYPE type SO_OBJ_TP
      !BODY type STRING
      !SENDER_UID type SYUNAME optional
      !SENDER_MAIL type ADR6-SMTP_ADDR optional .
  methods ADD_ATTACHMENT
    importing
      !FILE_EXT type STRING
      !FILE_NAME type STRING
      !CONTENT type ANY
      !IS_TEXT type FLAG .
  methods ADD_RECIPIENT
    importing
      !RECIPIENT_UID type SYUNAME optional
      !RECIPIENT_MAIL type ADR6-SMTP_ADDR optional
      !RECIPIENT_ANY type CLIKE optional
      !EMAIL_BY_UID type C optional
      !RECIPIENT_UID_TAB type TY_UID_TAB optional
      !RECIPIENT_EMAIL_TAB type TY_EMAIL_TAB optional .
  methods SEND
    importing
      !SEND_IMMEDIATELY type FLAG optional
    returning
      value(SENT_TO_ALL) type OS_BOOLEAN .
  class-methods GET_EMAIL_BY_UID
    importing
      !UID type SYUNAME
    returning
      value(EMAIL) type STRING .
protected section.
private section.

  types:
    BEGIN OF ty_attachment,
      type      TYPE soodk-objtp,
      subject   TYPE sood-objdes,
      contetnt  TYPE string,
      contetntx TYPE xstring,
    END   OF ty_attachment .
  types:
    ty_attachment_tab TYPE STANDARD TABLE OF ty_attachment .
ENDCLASS.



CLASS YDK_CL_MAIL_SEND IMPLEMENTATION.


  METHOD add_attachment.
    IF is_text = 'X'.
      document->add_attachment(
         i_attachment_type    = CONV #( file_ext )
         i_attachment_subject = CONV #( file_name )
         i_attachment_size    = CONV #( strlen( content ) )
         i_att_content_text   = cl_bcs_convert=>string_to_soli( content )
         i_attachment_header  = VALUE #( ( |&SO_FILENAME={ file_name }.{ file_ext }| ) )
      ).
    ELSE.
      document->add_attachment(
         i_attachment_type    = CONV #( file_ext )
         i_attachment_subject = CONV #( file_name )
         i_attachment_size    = CONV #( xstrlen( content ) )
         i_att_content_hex    = cl_bcs_convert=>xstring_to_solix( content )
         i_attachment_header  = VALUE #( ( |&SO_FILENAME={ file_name }.{ file_ext }| ) )
      ).
    ENDIF.
  ENDMETHOD.


  METHOD add_recipient.
    DATA: lo_recipient TYPE REF TO if_recipient_bcs.
    DATA: email TYPE string.

    DO 3 TIMES.
      CASE sy-index.
        WHEN 1.
          CHECK recipient_uid IS SUPPLIED.
          IF email_by_uid CA 'XY'.
            email = get_email_by_uid( recipient_uid ).
            IF NOT email IS INITIAL.
              lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( email ) ).
            ENDIF.
          ENDIF.
          CHECK email_by_uid <> 'X'.

          lo_recipient = cl_sapuser_bcs=>create( recipient_uid ).
        WHEN 2.
          CHECK recipient_mail IS SUPPLIED.
          lo_recipient = cl_cam_address_bcs=>create_internet_address( recipient_mail ).
        WHEN 3.
          CHECK recipient_any IS SUPPLIED.
          IF recipient_any CS '@'.
            lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( recipient_any ) ).
          ELSE.
            IF email_by_uid CA 'XY'.
              email = get_email_by_uid( CONV #( recipient_any ) ).
              IF NOT email IS INITIAL.
                lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( email ) ).
                send_request->add_recipient( i_recipient = lo_recipient i_express = 'X' ).
              ENDIF.
            ENDIF.
            CHECK email_by_uid <> 'X'.

            lo_recipient = cl_sapuser_bcs=>create( CONV #( recipient_any ) ).
          ENDIF.
      ENDCASE.

      send_request->add_recipient( i_recipient = lo_recipient i_express = 'X' ).
    ENDDO.

    IF recipient_uid_tab IS SUPPLIED.
      LOOP AT recipient_uid_tab ASSIGNING FIELD-SYMBOL(<uid>).
        IF email_by_uid CA 'XY'.
          email = get_email_by_uid( <uid>-uname ).
          IF NOT email IS INITIAL.
            lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( email ) ).
            send_request->add_recipient( i_recipient = lo_recipient i_express = 'X' ).
          ENDIF.
        ENDIF.
        CHECK email_by_uid <> 'X'.

        lo_recipient = cl_sapuser_bcs=>create( <uid>-uname ).
        send_request->add_recipient( i_recipient = lo_recipient i_express = 'X' ).
      ENDLOOP.
    ENDIF.

    IF recipient_email_tab IS SUPPLIED.
      LOOP AT recipient_email_tab ASSIGNING FIELD-SYMBOL(<recipient_email>).
        lo_recipient = cl_cam_address_bcs=>create_internet_address( <recipient_email> ).
        send_request->add_recipient( i_recipient = lo_recipient i_express = 'X' ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    DATA: lt_text TYPE bcsy_text.
    DATA: lo_sender TYPE REF TO if_sender_bcs.

    send_request = cl_bcs=>create_persistent( ).

    send_request->set_message_subject( ip_subject = subject ).

    CALL METHOD cl_bcs_convert=>string_to_soli
      EXPORTING
        iv_string = body
      RECEIVING
        et_soli   = lt_text.

    document = cl_document_bcs=>create_document(
                   i_type    = body_type
                   i_text    = lt_text
                   i_length  = CONV #( strlen( body ) )
                   i_subject = CONV #( subject ) ).

    IF sender_mail IS NOT INITIAL.
      lo_sender = cl_cam_address_bcs=>create_internet_address( sender_mail ).
    ELSEIF sender_uid IS NOT INITIAL.
      lo_sender = cl_sapuser_bcs=>create( sender_uid ).
    ELSE.
      lo_sender = cl_sapuser_bcs=>create( sy-uname ).
    ENDIF.

    send_request->set_sender( i_sender = lo_sender ).
  ENDMETHOD.


  METHOD get_email_by_uid.
    SELECT SINGLE adr6~smtp_addr INTO email
      FROM usr21
      JOIN adr6
        ON adr6~persnumber = usr21~persnumber
       AND adr6~addrnumber = usr21~addrnumber
     WHERE usr21~bname = uid
       AND adr6~date_from = '00010101'
       AND adr6~smtp_addr <> ''.
    CHECK sy-subrc <> 0.

    DATA: pernr TYPE pa0105-pernr.

    SELECT SINGLE pernr INTO pernr
      FROM pa0105
     WHERE usrid = uid
       AND subty = '0001'
       AND endda >= sy-datum
       AND begda <= sy-datum.
    CHECK sy-subrc = 0.

    SELECT SINGLE usrid INTO email
      FROM pa0105
     WHERE pernr = pernr
       AND subty = 'MAIL'
       AND endda >= sy-datum
       AND begda <= sy-datum.
  ENDMETHOD.


  METHOD send.
    send_request->set_document( document ).

    IF send_immediately = 'X'.
      send_request->set_send_immediately( 'X' ).
    ENDIF.

    sent_to_all = send_request->send( i_with_error_screen = 'X' ).
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
