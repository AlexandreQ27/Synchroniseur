#!/bin/bash -i
#Version 1.0
#Author Qiu Yibo Xiao Wenting 
#linux_project


Path_A=~/Projet/A/				#Le chemin de l'arbre A
Path_a=~/Projet/A				#Le chemin pour créer dossier A
Path_B=~/Projet/B/				#Le chemin de l'arbre B
Path_b=~/Projet/B				#Le chemin pour créer dossier B
Path_L=~/.synchro/Journal.log		#Le chemin du journal
#=================================================================================================
#synchroniser les fichiers dans ce répertoire de script 
#(Les fichiers temporaires lors de la synchronisation)
Log_A=~/Projet/Sychroniseur/Log_A		#Enregistrer des informations sur le fichier dans le dossier A
Log_B=~/Projet/Sychroniseur/Log_B		#Enregistrer des informations sur le fichier dans le dossier B
#================================================================================================
flag1=0
flag2=0
#initialisation
#Créer les dossiers dont nous avons besoin
init(){
	if [ -d $Path_A ];then
		echo -e "Le dossier A existe"
	else
		mkdir -p $Path_a
		echo -e "A été créé avec succès"
	fi

	if [ -d $Path_B ];then
		echo -e "Le dossier B existe"
	else
		mkdir -p $Path_b
		echo -e "B été créé avec succès"
	fi
	if [ ! -r $Path_L ];then
		mkdir -p $Path_l
		touch  $Path_L
		echo -e "Le journal été créé avec succès"
	fi
	if [ ! -e $Log_A ];then
		mkdir -p ~/Projet/Sychroniseur
	 	touch  $Log_A
		echo -e "Le journal A temporaire été créé avec succès"
	fi
	if [ ! -e $Log_B ];then
		touch  $Log_B
		echo -e "Le journal B temporaire été créé avec succès"
	echo -e "\n"
	fi
}
#Obtenir les détails du fichier (compris l’heure de dernière modification, les propriétés du fichier, la taille du fichier, le chemin du fichier)
#Trier par liens symboliques, répertoires, fichiers normaux
get_information(){
	if [ -L $1$2  ]
	then
		ls -l $1$2 | cut -c1 | awk '{ printf "%s\t", $1}'
		ls -l $1$2 | cut -c2-10 | awk '{ printf "%s\t", $1}'
		ls -l $1$2 | awk '{ printf "%s\t%s-%s-%s\t" , $5, $6, $7, $8 }'
		printf "$1$2\t"
		ls -l $1$2 | awk '{ printf "%s\t%s\t" ,$10,$11}'
		printf "\n"
	elif [ -d $1$2 ]
	then
		ls -ld $1$2 | cut -c1 | awk '{ printf "%s\t", $1}' 
		ls -ld $1$2 | cut -c2-10 | awk '{ printf "%s\t", $1}'
		ls -ld $1$2 | awk '{ printf "%s\t%s-%s-%s\t" ,$5, $6, $7, $8 }'
		printf "$1$2\n"
	elif [ -f $1$2 ]
	then
		ls -l $1$2 | cut -c1 | awk '{ printf "f\t"}' 
		ls -l $1$2 | cut -c2-10 | awk '{ printf "%s\t", $1}'
		ls -l $1$2 | awk '{ printf "%s\t%s-%s-%s\t" ,$5, $6, $7, $8 }'
		printf "$1$2\n"
	fi
}
#À partir des logs pour obtenir des informations sur les fichiers dans les logs en fonction des mots clés dans les chemins
#Exclure l’influence du chemin sur les résultats de la comparaison entre logs et fichiers en jugeant s’il s’agit d’un fichier de lien symbolique
get_log(){
	if [ -L $1 ]
	then
		echo $(grep $1 $2 | awk '{print $1,$2,$3,$4}')
	else
		echo $(grep $1 $2 | grep -v '\->' | awk '{print $1,$2,$3,$4}')
	fi
}
#Obtenir les détails du fichier et la sortie(compris l’heure de dernière modification, les propriétés du fichier, la taille du fichier, le chemin du fichier)
get_data(){
  	echo $(get_information $1 $2 | awk '{print $1,$2,$3,$4}')
}

#Obtenir le chemin vers lequel pointent les fichiers de lien symbolique
get_address(){
	echo $(get_information $1 $2 | awk '{print $7}')
}

#Évaluer les différences de métadonnées
different(){	
	diff -c $1"/"$3 $2"/"$3 | while read diffline && [ -n "$diffline" ]
	do 
		deal $1 $2 $3
		break
        done
	#Si les deux sont des fichiers liés du même nom, le contenu du fichier est le même, mais le chemin du lien est différent
	if [[ -L $1$3 && -L $2$3 ]]
	then
		#Déterminer si les deux chemins de lien sont cohérents
		if [[ `get_address $1 $3 ` != ` get_address $2 $3 ` ]]
		then
			flag3=1
			while [ $flag3 -ne 0 ]
			do  
				echo "Le chemin de lien entre les deux fichiers est différent, veuillez sélectionner une action"
				echo "1.Synchroniser le fichier comme chemin de lien de $3 en $1 `get_address $1 $3`"
				echo "2.Synchroniser le fichier comme chemin de lien de $3 en $2 `get_address $2 $3`"
				read -p "Veuillez entrer :" choix_lianjie input </dev/tty
				case $choix_lianjie in
				1)
					echo "Synchroniser le fichier comme chemin de lien de $3 en $1 `get_address $1 $3`"
					rm -rf $2$3
					cp -rpf $1$3 $2$3
					flag3=0;;
				2)
					echo "Synchroniser le fichier comme chemin de lien de $3 en $2 `get_address $2 $3`"
					rm -rf $1$3
					cp -rpf $2$3 $1$3
					flag3=0;;
				*)
					echo "Erreur de saisie, veuillez saisir à nouveau"
				esac
			done
		fi
	#Normalement, selon la comparaison avec le journal, vous pouvez trouver que le type de fichier a changé avant et après la synchronisation
	#Mais si la synchronisation s’arrête de force(Ctrl-Z), les fichiers en A,B ne sont pas comparés entre eux
	#Cas où le fichier a le même contenu, est de type différent, mais affiche indifférencié
	elif [ -L $1$3 ]
	then
		echo -e "$3 est un fichier normal dans $2,$3 est un lien symbolique dans $1,le chemin de lien est `get_address $1 $3`\n"
		echo "Veuillez sélectionner "
		echo "1.Tout devient un fichier de lien symbolique，le chemin de lien est `get_address $1 $3`"
		echo "2.Tout devient un fichier normal"
		read -p "Veuillez entrer :" choix_lianjie_1 input </dev/tty
		case $choix_lianjie_1 in
		1)
			echo "Tout devient un fichier de lien symbolique，le chemin de lien est `get_address $1 $3`"
			rm -rf $2$3
			cp -rpf $1$3 $2$3
			flag3=0;;
		2)
			echo "Tout devient un fichier normal"
			rm -rf $1$3
			cp -rpf $2$3 $1$3
			flag3=0;;
		*)
			echo "Erreur de saisie, veuillez saisir à nouveau"
		esac
	elif [ -L $2$3 ]
	then
		echo -e "$3 est un fichier normal dans $1,$3 est un lien symbolique dans $2,le chemin de lien est `get_address $2 $3`\n"
		echo "Veuillez sélectionner "
		echo "1.Tout devient un fichier de lien symbolique，le chemin de lien est `get_address $2 $3`"
		echo "2.Tout devient un fichier normal"
		read -p "Veuillez entrer :" choix_lianjie_2 input </dev/tty
		case $choix_lianjie_2 in
		1)
			echo "Tout devient un fichier de lien symbolique，le chemin de lien est `get_address $2 $3`"
			rm -rf $2$3
			cp -rpf $1$3 $2$3
			flag3=0;;
		2)
			echo "Tout devient un fichier normal"
			rm -rf $1$3
			cp -rpf $2$3 $1$3
			flag3=0;;
		*)
			echo "Erreur de saisie, veuillez saisir à nouveau"
		esac
		
	fi
		
}
#Résoudre les conflits et laisser l’utilisateur décider de la méthode de détermination des conflits
deal(){
	echo "---------------------deal------------------------------"
	flag1=1
	echo "Un conflit apparaît, l’utilisateur est invité à gérer les conflits"
        diff -c $1"/"$3 $2"/"$3
	while [ $flag1 -ne 0 ]
	do  
		echo "1.Supprimer $3 de $1."
		echo "2.Supprimer $3 de $2."
		read -p "Veuillez entrer :" choix input </dev/tty
		case $choix in
		1)
			echo "Supprimer $3 de $1，Copier $3 de $2 vers $1"
			rm -rf $1$3
			cp -rpf $2$3 $1$3
			flag1=0;;
		2)
			echo "Supprimer $3 de $2，Copier $3 de $1 vers $2"
			rm -rf $2$3
			cp -rpf $1$3 $2$3
			flag1=0;;
		*)
			echo "Erreur de saisie, veuillez saisir à nouveau"
		esac
	done
}
#Mise à jour le journal
update_log(){
	#Vider le message original dans le Journal，Prêt à réécrire
	cat /dev/null > $Path_L 
	#Comme le contenu de l’arborescence A, B est le même après la synchronisation, le Journal original est mis à jour en fonction des informations du fichier dans A
	ls $1|while read ligne
	do
		get_information $1 $ligne >>$Path_L
		if [ -d $1$ligne ]
		then
			update_path_information $1$ligne"/" $Path_L
		fi	
	done
	echo "Mettre à jour le journal avec succès!"
}
#Mettre à jour les journaux sous les chemins A et B
update_path_information(){
	ls $1|while read ligne
	do
		#echo "`get_information $1 $ligne`"
		get_information $1 $ligne >>$2
		#printf "\n"
                #cat $2
		if [ -d $1$ligne ]
		then
			update_path_information $1$ligne"/" $2
		fi	
	done
}
#Combine les logs de synchronisation pour comparer le contenu des arbres A et B. Effectuer des opérations de copie et de suppression de fichiers différentiels
compare_file(){
	ls $1 | while read ligne
	do
		echo -e "Commencez à comparer si les journaux et les fichiers sont différents\n"
		if [ -e $3$ligne ] #Le fichier existe
		then
			echo "Dans $ligne, $3 existe déjà"
			#Déterminer si p/A et p/B sont tous deux des fichiers ordinaires
			if [[ -f $1$ligne && -f $3$ligne ]]
			then
				echo "les deux documents sont tous des fichiers ordinaires"
				#Comparer les informations des deux fichiers avec les informations du journal
				if [[ `get_data $1 $ligne ` == `get_log $1$ligne $2 ` && ` get_data $3 $ligne ` == ` get_log $3$ligne $4 ` ]]
				then
					echo "les deux fichiers ont les même mode, taille et date de dernière modification"
					echo "La différence entre les métadonnées des deux fichiers sera comparée"
					different $1 $3 $ligne
				else
					echo "Les données du fichier sont différentes de celles du dernier log"
					deal $1 $3 $ligne
				fi
			#Un pour les fichiers ordinaire l’autre pour les répertoires 
			elif [[ -d $1$ligne && -f $3$ligne ]]
			then
				echo -e "il y a conflit，$ligne  est un répertoire dans A, mais il est un fichier dans B.\n"
				deal $1 $3 $ligne
			elif [[ -f $1$ligne && -d $3$ligne ]]
			then
				echo -e "il y a conflit，$ligne  est un répertoire dans B, mais il est un fichier dans A.\n"
				deal $1 $3 $ligne
			#p/A et p/B sont tous deux des répertoires
			elif [[ -d $1$ligne && -d $3$ligne ]]
			then
				echo -e "Ils sont tous des répertoires,le synchroniseur descend récursivement.\n"
				compare_file $1$ligne"/" $2 $3$ligne"/" $4
			fi
		else
			echo "$ligne ne exist pas dans $3.Veuillez sélectionner copier ou supprimer"
			flag2=1
			while [ $flag2 -ne 0 ]
			do  
				echo "1.Copier dans $3 pour sauvegarder"
				echo "2.Supprimer $ligne de $1."
				read -p "Veuillez entrer :" choix input </dev/tty
				case $choix in
				1)
					if [ -L $1$ligne ]
					then
						echo "Le fichier est un fichier de lien symbolique. Le chemin du lien est `get_address $1 $ligne`，Veuillez sélectionner"
						echo "1.Synchroniser les liens, copier sauvegarder un fichier de lien symbolique."
						echo "2.Déréférencement, suppression des fichiers de liens symboliques"
						read -p "Veuillez entrer :" choixL input </dev/tty
						case $choixL in		
						1)
							cp -rpf $1$ligne $3$ligne
							echo "Synchroniser les liens, copier sauvegarder un fichier de lien symbolique"
							flag2=0
							;;
						2)
							echo "Déréférencement, suppression des fichiers de liens symboliques"
							rm -rf $1$ligne
							flag2=0
							;;
						*)
							echo "Erreur de saisie, veuillez saisir à nouveau"
							;;
						esac
					else			
						cp -rpf $1$ligne $3$ligne
						echo "Copiez avec succès"
						flag2=0
					fi
					;;
				2)
					echo "Supprimer $ligne de $1"
					rm -rf $1$ligne
					flag2=0
					;;
				*)
					echo "Erreur de saisie, veuillez saisir à nouveau"
					;;
				esac
			done
		fi
	done
}
echo "-----------------------init----------------------------"
init
#Faire deux comparaisons
echo "-------------------compare_file------------------------"
compare_file $Path_A $Log_A $Path_B $Log_B
compare_file $Path_B $Log_B $Path_A $Log_A
#Après chaque comparaison, vider les logs temporaires de A, B
cat /dev/null >$Log_A
cat /dev/null >$Log_B
#Mettre à jour les journaux sous les chemins A et B 
echo -e "---------------update_path_information-----------------\n"
update_path_information $Path_A $Log_A
update_path_information $Path_B $Log_B
#Le synchroniseur réécrit le fichier de journal avec les données de tous les fichiers ordinaires dont la synchronisation a réussi.
echo "--------------------update_log-------------------------"
update_log $Path_A






