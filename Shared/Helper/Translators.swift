//
//  Translators.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 21.08.21.
//

import Foundation

struct Language: Hashable {
    var name: String
    var flag: String
    var maintainers: String
    var contributors: [String]
}

struct Translators {
    static let english = Language(
        name: "English",
        flag: "🇬🇧",
        maintainers: "Georg Meißner",
        contributors: [
            "Bernd Bestel <bernd@berrnd.de>, 2021"
        ]
    )
    static let german = Language(
        name: "Deutsch",
        flag: "🇩🇪",
        maintainers: "Georg Meißner",
        contributors: [
            "Luca RHK <luca@rhk-in.de>, 2020",
            "Tobias Wolter <mumpfpuffel@gmail.com>, 2020",
            "@RubenKelevra <ruben@freifunk-nrw.de>, 2021",
            "Bernd Bestel <bernd@berrnd.de>, 2021"
        ]
    )
    static let polish = Language(
        name: "Polish",
        flag: "🇵🇱",
        maintainers: "Paweł Klebba",
        contributors: [
            "Agata Prymuszewska <a.prymuszewska@gmail.com>, 2019",
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Zbigniew Żołnierowicz <zbigniew.zolnierowicz@gmail.com>, 2019",
            "Maczuga <maczugapl@gmail.com>, 2019",
            "Piotr Oleszczyk <piotr.oleszczyk@gmail.com>, 2020",
            "Teiron, 2020",
            "Pro Peller <smiglo@tuta.io>, 2020",
            "Rafal Dadas <dadasrafal@gmail.com>, 2020",
            "Marcin Radoszewski <moriturius@gmail.com>, 2021",
            "Konrad Mazurczak <konrad.mazurczak@gmail.com>, 2021",
            "Marcin Redlica <marcin.redlica@gmail.com>, 2021",
            "Jakub Kluba <jakub.kluba@gmail.com>, 2021"
        ]
    )
    static let french = Language(
        name: "French",
        flag: "🇫🇷",
        maintainers: "Will711990 & chpego",
        contributors: [
            "bigoudo, 2019",
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Hydreliox <hydreliox@gmail.com>, 2019",
            "Matthieu K, 2019",
            "Jérémy Tisserand <jeremy.tisserand@gmail.com>, 2019",
            "Mathieu Fortin <mathieugfortin@gmail.com>, 2019",
            "Pierre-Emmanuel Colas <transiflex@atnock.fr>, 2019",
            "Antonin DESFONTAINES <antonin.desfontaines@outlook.com>, 2019",
            "Adrien Guillement <adrien.guillement@gmail.com>, 2019",
            "Matthias Baumgartner <dersoistargate@gmail.com>, 2019",
            "Guillaume RICHARD <giz.richard@gmail.com>, 2020",
            "Bastien SOL <agentcobra57@gmail.com>, 2020",
            "Bruno D'agen <iamlionem@gmail.com>, 2020",
            "Nicolas Moisson <nicolas.moisson@protonmail.com>, 2020",
            "Gregory Pelletier <gpelletier@ip512.com>, 2020",
            "Sacha D <contact@shaac.me>, 2020",
            "Julien Ferga <palalex38@gmail.com>, 2020",
            "S Hugeee <sebsebsebseb007@gmail.com>, 2020",
            "Renaud Martinet <me+github@renaudmarti.net>, 2020",
            "Pierre Dumoulin <dumoulinpierre@icloud.com>, 2020",
            "Tristan <tristan@lesbringuier.net>, 2020",
            "Jordan COUTON <couton.jordan@gmail.com>, 2020",
            "Juan RODRIGUEZ <juansero29@gmail.com>, 2020",
            "Clément CHABANNE <clementchabanne@gmail.com>, 2020",
            "Daniel Nautré <daniel.nautre@gmail.com>, 2020",
            "nerdinator <florian.dupret@gmail.com>, 2020",
            "C P <anoxy78@gmail.com>, 2020",
            "voslin <web@frugier.net>, 2021",
            "Julien Pidoux <julien@pidoux.me>, 2021",
            "Zorvalt - <zorvalt@protonmail.ch>, 2021",
            "Zkryvix <angelo.frangione@gmail.com>, 2021",
            "patate douce <poubel125@gmail.com>, 2021",
            "Cedric Octave <transifex@octvcdrc.fr>, 2021",
            "Alexandre Mechineau <admin@alexsaphir.com>, 2021",
            "Pierre Penninckx <ibizapeanut@gmail.com>, 2021"
        ]
    )
    static let dutch = Language(
        name: "Dutch",
        flag: "🇳🇱",
        maintainers: "Heimen Stoffels",
        contributors: [
            "Llewy <carlvanoene@gmail.com>, 2019",
            "Adriaan Peeters <apeeters@lashout.net>, 2019",
            "Seppe <van.winkel.seppe@me.com>, 2019",
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Jelte L <jelte@ollavogala.org>, 2019",
            "Tarik Faik <filoor1@gmail.com>, 2019",
            "Niels Tholenaar <info@123quality.nl>, 2019",
            "Kees van Nieuwenhuijzen <kees@vannieuwenhuijzen.com>, 2019",
            "BodingClockchian <joost_nl@live.nl>, 2020",
            "gggg <bashankamp@gmail.com>, 2020",
            "Bastien Van Houdt <bastienvanhoudt@gmail.com>, 2020",
            "D. Polders <zigurana@gmail.com>, 2020",
            "crnh <corne@haasjes.nu>, 2020",
            "Sigi 789 <ssigi333lvl3@outlook.com>, 2020",
            "Jesse Nagel <jnagel24@gmail.com>, 2020",
            "Peter van den Heuvel <peter@pvandenheuvel.nl>, 2020",
            "ellem, 2020",
            "Frank <frank@frankklaassen.nl>, 2020",
            "Stan Overgauw <stan.overgauw@gmail.com>, 2020",
            "L. P. <lloyd4post11@hotmail.com>, 2021",
            "Jeroen Blevi <jeroen@triponoid.com>, 2021",
            "Anne Gerben van Assen <annegerben+transifex@vanassen.eu>, 2021",
            "Sebastiaan Ammerlaan <steelbas@gmail.com>, 2021",
            "Mark Peters <forkless@gmail.com>, 2021",
            "Daan Breur <daanbreur@gmail.com>, 2021",
            "Grocy NL, 2021",
            "mc bloch <transifex@mcbloch.dev>, 2021",
            "Gerard stn, 2021",
            "Simon Bor <mail@simonbor.nl>, 2022"
        ]
    )
    static let czech = Language(
        name: "Czech",
        flag: "🇨🇿",
        maintainers: "zemanl79",
        contributors: [
            "Tomas Reznicek <tomas.reznicek@gmail.com>, 2019",
            "Michal Petříček <michal@petricek.org>, 2019",
            "Jose Riha <jose1711@gmail.com>, 2020",
            "Matyas Bobek <matyas.bobek@gmail.com>, 2020",
            "Adam Kroupa <mavi222@seznam.cz>, 2020",
            "Radim Kabeláč <radim.ekk@gmail.com>, 2020",
            "Jaroslav Lichtblau <jlichtblau@seznam.cz>, 2020",
            "Jarda Tesar <intossh@gmail.com>, 2021",
            "Pavel Paseka, 2022",
        ]
    )
    static let italian = Language(
        name: "Italian",
        flag: "🇮🇹",
        maintainers: "mike9449",
        contributors: [
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Matteo Piotto <matteo.piotto@welaika.com>, 2019",
            "42d76af3cd20bc399c7e8a413695959f, 2019",
            "Matteo Piccina <altermatte@gmail.com>, 2021",
            "Sergio Zampello <seriotv88@gmail.com>, 2021",
            "Antonino Ursino <ninus_@libero.it>, 2022",
            "Walter Palagi, 2022",
            "Moltivie Denied <major2015usa@gmail.com>, 2022",
        ]
    )
    
    static let chinese_simplified = Language(
        name: "Chinese (Simplified)",
        flag: "🇨🇳",
        maintainers: "3L/404alex/WeydonDing",
        contributors: [
            "a a <akv40402@zzrgg.com>, 2020",
            "文春鹏 <wcp1231@gmail.com>, 2020",
            "milkfish <i@mxd.moe>, 2020",
            "ba X <985096998@qq.com>, 2022",
            "Xuesong, 2022",
            "Weicheng Ao, 2022",
            "冠南 胡, 2023",
            "foo bar, 2023",
            "石磊, 2023",
        ]
    )
    
    static let portuguese_PT = Language(
        name: "Portuguese (Portugal)",
        flag: "🇵🇹",
        maintainers: "otshug/Ricardo.O",
        contributors: [
            "Ricardo Rodrigues <fenix999@gmail.com>, 2020",
            "Miguel Pereira <miguelpereira.pro@gmail.com>, 2020",
            "Carlos Pereira <cmp.sta@gmail.com>, 2020",
            "Joao Santos <joaocpdsantos@gmail.com>, 2022",
            "Luís Neto, 2022",
            "Francisco Norton Brandão, 2022",
            "Jorge Araújo, 2022",
            "João Queirós, 2022",
            "Cesar Veloso, 2023",
        ]
    )
    
    static let languages: Set<Language> = [english, german, french, polish, dutch, czech, italian, chinese_simplified, portuguese_PT]
}
