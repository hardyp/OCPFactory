class ZCL_OCP_DEPENDENCIES definition
  public
  final
  create public .

public section.

  interfaces ZIF_APACK_MANIFEST .

  methods CONSTRUCTOR .
protected section.
private section.
ENDCLASS.



CLASS ZCL_OCP_DEPENDENCIES IMPLEMENTATION.


  METHOD constructor.

    zif_apack_manifest~descriptor = VALUE #(
       group_id        = 'hardyp'
       artifact_id     = 'OCPFactory'
       version         = '0.1'
       repository_type = zif_apack_manifest~co_abap_git
       git_url         = 'https://github.com/hardyp/OCPFactory'
       dependencies    = VALUE #(
         ( group_id    = 'hardyp'
           artifact_id = 'DesignByContract'
           git_url     = 'https://github.com/hardyp/DesignByContract' ) ) ).

  ENDMETHOD.
ENDCLASS.
