with open("questid2display.txt", "w", encoding="1251") as f:
    for i in range(1000, 100000):
        content = f"{i}#Квест#SG_FEEL#QUE_IMAGE#\nТекст квеста\n#\n\n"
        f.write(content)
