## SAP ABAP mail sending
SAP standard set of classes for sending mail named BCS is very difficult to use, it has a several problems that can be solved in very unsightly ways.
So I wrote one simple wrapper class which is easy and pleasant to work with.
I think in some very complicated cases you may need to use standard BCS, but in most cases my class is quite enough.

To install this on SAP server, use [abapGit](https://docs.abapgit.org/)

**Class YDK_CL_MAIL_SEND**  
methods:
* CONSTRUCTOR - creates a class instance of the mail.                                              
* ADD_ATTACHMENT - adding an attachment to the mail
* ADD_RECIPIENT - adding recipients to the mail
* SEND - sending the mail

the corresponding BCS objects remain accessible through class attributes:  
* SEND_REQUEST Type Ref To CL_BCS
* DOCUMENT Type Ref To CL_DOCUMENT_BCS

**Example of use:**
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