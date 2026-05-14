import 'package:flutter/material.dart';
import 'MainContent.dart';

class CouponListItem extends StatelessWidget {

  final VoidCallback onPressed;
  const CouponListItem(this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(10),

        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 3)]),

        child: Row(children: [
          Container(
            width: 100,
            height: 100,
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 1)]),
            child: imageWidget(),
          ),
          Expanded(
          child: SizedBox(
            height: 100,
            child: MainContent(onPressed)
          )
        )
        ]));
  }

  //  画像を表示
  Widget imageWidget(){
    return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: Image.asset('assets/images/c_img.jpg'),
        )
    );
  }
}
