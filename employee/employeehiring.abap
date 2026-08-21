  METHOD if_rest_resource~post.
*CALL METHOD SUPER->IF_REST_RESOURCE~POST
*  EXPORTING
*    IO_ENTITY =
*    .
    TYPES: BEGIN OF ty_messages,
             type TYPE char01,
             text TYPE string,
           END OF ty_messages.
    TYPES: BEGIN OF ty_response,
             employeeid TYPE char10,
             status     TYPE string,
             messages   TYPE TABLE OF ty_messages WITH NON-UNIQUE DEFAULT KEY,
           END OF ty_response.

    DATA: lo_entity_n         TYPE REF TO if_rest_entity,
          ls_payload_response TYPE ty_response,
          lv_json_string      TYPE string,
          lv_pernr_new        TYPE pernr_d,
          lt_return           TYPE TABLE OF bdcmsgcoll,
          lv_text             TYPE string,
          ls_messages         TYPE ty_messages
          .


    " Local Entity
    DATA(lo_entity) = mo_request->get_entity( ).
    DATA(lv_payload_json) = io_entity->get_string_data( ). "Payload

    " Call function for Hiring action execution
    CALL FUNCTION 'ZHCM_EMP_HIRING_UPD'
      EXPORTING
        iv_payload = lv_payload_json
      IMPORTING
        ev_pernr   = lv_pernr_new
      TABLES
        et_return  = lt_return.

*    /ui2/cl_json=>deserialize(
*      EXPORTING
*        json = lv_payload
*      CHANGING
*        data = ls_payload
*      ).

    " Set Response
    " Populate your response structure
    IF lv_pernr_new IS INITIAL AND line_exists( lt_return[ msgtyp = 'E' ] ).
      ls_payload_response-status     = 'E'.
      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<fsret>).
        MESSAGE ID <fsret>-msgid
          TYPE <fsret>-msgtyp
          NUMBER <fsret>-msgnr
          WITH <fsret>-msgv1 <fsret>-msgv2 <fsret>-msgv3 <fsret>-msgv4
          INTO lv_text.
        ls_messages-type    = <fsret>-msgtyp.
        ls_messages-text    = lv_text.
        APPEND ls_messages TO ls_payload_response-messages.
      ENDLOOP.
    ELSE.
      ls_payload_response-employeeid = lv_pernr_new.
      ls_payload_response-status     = 'S'.
      ls_payload_response-messages    = VALUE #( ( type = 'S' text = 'Employee Hired successfully.' ) ).
    ENDIF.

    " Serialize the ABAP structure to a JSON string
    lv_json_string = /ui2/cl_json=>serialize( data = ls_payload_response ).

    " Create the response entity
    lo_entity_n = mo_response->create_entity( ).

    " Set the content type to JSON
    lo_entity_n->set_content_type( if_rest_media_type=>gc_appl_json ).

    " Pass the JSON string as the response body
    lo_entity_n->set_string_data( lv_json_string ).

    " Set the HTTP status code (201 Created is standard for successful POST)
    IF ls_payload_response-status     = 'S'.
      mo_response->set_status( cl_rest_status_code=>gc_success_created ).
    ENDIF.

  ENDMETHOD.
