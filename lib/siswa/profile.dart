import 'package:flutter/material.dart';


class ProfilePage extends StatelessWidget {

  const ProfilePage({super.key});


  @override
  Widget build(BuildContext context) {


    return Container(

      color: const Color(0xffF7FCFA),


      child: SafeArea(

        child: SingleChildScrollView(


          padding: const EdgeInsets.only(

            left:20,

            right:20,

            top:40,

            bottom:40,

          ),



          child: Column(


            crossAxisAlignment:
                CrossAxisAlignment.center,



            children:[



              // PROFILE IMAGE


              CircleAvatar(

                radius:50,


                backgroundColor:
                    Colors.green.shade100,



                child:const Icon(

                  Icons.person,

                  size:60,

                  color:
                      Color(0xff009B88),

                ),

              ),





              const SizedBox(height:15),





              const Text(

                "Andi Pratama",


                style:TextStyle(

                  fontSize:22,

                  fontWeight:
                      FontWeight.bold,

                ),

              ),




              const SizedBox(height:5),





              Text(

                "Siswa • Kelas XI IPA 2",


                style:TextStyle(

                  fontSize:14,

                  color:
                      Colors.grey.shade600,

                ),

              ),





              const SizedBox(height:30),





              // MENU PROFILE


              profileCard(

                icon:Icons.person_outline,

                title:"Data Pribadi",

                subtitle:"Lihat dan ubah informasi diri",

              ),





              profileCard(

                icon:Icons.school_outlined,

                title:"Informasi Sekolah",

                subtitle:"SMAN 1 Contoh",

              ),





              profileCard(

                icon:Icons.lock_outline,

                title:"Ubah Password",

                subtitle:"Ganti password akun",

              ),





              profileCard(

                icon:Icons.notifications_none,

                title:"Notifikasi",

                subtitle:"Atur pemberitahuan",

              ),





              profileCard(

                icon:Icons.help_outline,

                title:"Bantuan",

                subtitle:"Pusat bantuan Ruang Aman",

              ),





              const SizedBox(height:20),





              // LOGOUT


              Container(

                width:
                    double.infinity,


                height:50,



                decoration:BoxDecoration(

                  color:
                      Colors.red.shade50,


                  borderRadius:
                      BorderRadius.circular(25),

                ),



                child:const Center(


                  child:Row(

                    mainAxisAlignment:
                        MainAxisAlignment.center,


                    children:[


                      Icon(

                        Icons.logout,

                        color:Colors.red,

                      ),



                      SizedBox(width:8),




                      Text(

                        "Keluar",

                        style:TextStyle(

                          color:Colors.red,

                          fontWeight:
                              FontWeight.bold,

                        ),

                      ),


                    ],


                  ),


                ),


              ),



            ],


          ),


        ),


      ),


    );

  }






  Widget profileCard({

    required IconData icon,

    required String title,

    required String subtitle,

  }){


    return Container(


      margin:
          const EdgeInsets.only(bottom:12),



      padding:
          const EdgeInsets.all(16),




      decoration:BoxDecoration(

        color:
            Colors.white,


        borderRadius:
            BorderRadius.circular(18),



        boxShadow:[


          BoxShadow(

            color:
                Colors.black.withOpacity(0.05),


            blurRadius:
                10,

          )


        ],

      ),




      child:Row(


        children:[



          Container(

            width:45,

            height:45,



            decoration:BoxDecoration(

              color:
                  const Color(0xffE9F7F1),


              borderRadius:
                  BorderRadius.circular(14),

            ),



            child:Icon(

              icon,

              color:
                  const Color(0xff009B88),

            ),



          ),




          const SizedBox(width:15),





          Expanded(

            child:Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,


              children:[


                Text(

                  title,

                  style:const TextStyle(

                    fontSize:15,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),




                const SizedBox(height:3),




                Text(

                  subtitle,

                  style:TextStyle(

                    fontSize:12,

                    color:
                        Colors.grey.shade600,

                  ),

                ),


              ],

            ),

          ),





          const Icon(

            Icons.arrow_forward_ios,

            size:16,

            color:Colors.grey,

          )



        ],

      ),



    );


  }


}