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
            "Maczuga <maczugapl@gmail.com>, 2019",
            "Zbigniew Żołnierowicz <zbigniew.zolnierowicz@gmail.com>, 2019",
            "Marcin Szymański <cysioland@gmail.com>, 2020",
            "Piotr Oleszczyk <piotr.oleszczyk@gmail.com>, 2020",
            "Pro Peller <smiglo@tuta.io>, 2020",
            "Rafal Dadas <dadasrafal@gmail.com>, 2020",
            "Teiron, 2020",
            "Tomasz Dobrzański <verbanet@gmail.com>, 2020",
            "Jakub Kluba <jakub.kluba@gmail.com>, 2021",
            "Konrad Mazurczak <konrad.mazurczak@gmail.com>, 2021",
            "Marcin Radoszewski <moriturius@gmail.com>, 2021",
            "Marcin Redlica <marcin.redlica@gmail.com>, 2021",
            "Łukasz Wawrzyk, 2021",
            "Hans Müller, 2022",
            "Kamila Frej, 2022",
            "Michał G, 2022",
            "Tomasz Wieczorek <tomek12-96@o2.pl>, 2022",
            "Marcin Lewandowski <email.marcina.lewandowskiego@gmail.com>, 2023",
            "orl0pl, 2023",
            "Oskar Sawaryn, 2023",
            "Stanisław Czajka <stanislaw@czajka.pl>, 2023",
            "Peter Patalong <piotrpatalong@gmail.com>, 2024",
            "Dawid K., 2025",
            "Mateusz Bieniek, 2025",
            "Michal G-K, 2025",
        ]
    )
    static let french = Language(
        name: "French",
        flag: "🇫🇷",
        maintainers: "Will711990 & chpego",
        contributors: [
            "Adrien Guillement <adrien.guillement@gmail.com>, 2019",
            "Antonin DESFONTAINES <antonin.desfontaines@outlook.com>, 2019",
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "bigoudo, 2019",
            "Hydreliox <hydreliox@gmail.com>, 2019",
            "Jérémy Tisserand <jeremy.tisserand@gmail.com>, 2019",
            "Mathieu Fortin <mathieugfortin@gmail.com>, 2019",
            "Matthias Baumgartner <dersoistargate@gmail.com>, 2019",
            "Matthieu K, 2019",
            "Pierre-Emmanuel Colas <transiflex@atnock.fr>, 2019",
            "Bastien SOL <agentcobra57@gmail.com>, 2020",
            "Bruno D'agen <iamlionem@gmail.com>, 2020",
            "C P <anoxy78@gmail.com>, 2020",
            "Clément CHABANNE <clementchabanne@gmail.com>, 2020",
            "Daniel Nautré <daniel.nautre@gmail.com>, 2020",
            "Gregory Pelletier <gpelletier@ip512.com>, 2020",
            "Guillaume RICHARD <giz.richard@gmail.com>, 2020",
            "Jordan COUTON <couton.jordan@gmail.com>, 2020",
            "Juan RODRIGUEZ <juansero29@gmail.com>, 2020",
            "Julien Ferga <palalex38@gmail.com>, 2020",
            "nerdinator <florian.dupret@gmail.com>, 2020",
            "Nicolas Moisson <nicolas.moisson@protonmail.com>, 2020",
            "Pierre Dumoulin <dumoulinpierre@icloud.com>, 2020",
            "Renaud Martinet <me+github@renaudmarti.net>, 2020",
            "S Hugeee <sebsebsebseb007@gmail.com>, 2020",
            "Sacha D <contact@shaac.me>, 2020",
            "sebastien GRANDJEAN <maluseb@hotmail.fr>, 2020",
            "Tristan <tristan@lesbringuier.net>, 2020",
            "Alexandre Mechineau <admin@alexsaphir.com>, 2021",
            "Barthelemy Drabczuk, 2021",
            "Cedric Octave <transifex@octvcdrc.fr>, 2021",
            "Julien Pidoux <julien@pidoux.me>, 2021",
            "patate douce <poubel125@gmail.com>, 2021",
            "Pierre Penninckx <ibizapeanut@gmail.com>, 2021",
            "voslin <web@frugier.net>, 2021",
            "Zkryvix <angelo.frangione@gmail.com>, 2021",
            "Zorvalt - <zorvalt@protonmail.ch>, 2021",
            "chpego <chpego@chpego.fr>, 2022",
            "Jonathan Blanc, 2022",
            "Maxime Corteel, 2022",
            "Olivier Brencklé, 2022",
            "ThalusA, 2022",
            "Thomas Johanns, 2022",
            "Fred <github@chacsam.be>, 2023",
            "Greg G, 2023",
            "Lamecarlate, 2025",
            "Olivier R, 2025",
            "Vulf vulf, 2025",
            "Chom Chaum, 2026",
        ]
    )
    static let dutch = Language(
        name: "Dutch",
        flag: "🇳🇱",
        maintainers: "Heimen Stoffels",
        contributors: [
            "Adriaan Peeters <apeeters@lashout.net>, 2019",
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Engelbert Mercelis <engelbertmercelis@gmail.com>, 2019",
            "Jelte L <jelte@ollavogala.org>, 2019",
            "Kees van Nieuwenhuijzen <kees@vannieuwenhuijzen.com>, 2019",
            "Llewy <carlvanoene@gmail.com>, 2019",
            "Niels Tholenaar <info@123quality.nl>, 2019",
            "Seppe <van.winkel.seppe@me.com>, 2019",
            "Tarik Faik <filoor1@gmail.com>, 2019",
            "Bastien Van Houdt <bastienvanhoudt@gmail.com>, 2020",
            "BodingClockchian <joost_nl@live.nl>, 2020",
            "crnh <corne@haasjes.nu>, 2020",
            "D. Polders <zigurana@gmail.com>, 2020",
            "ellem, 2020",
            "Frank <frank@frankklaassen.nl>, 2020",
            "gggg <bashankamp@gmail.com>, 2020",
            "Jesse Nagel <jnagel24@gmail.com>, 2020",
            "Peter van den Heuvel <peter@pvandenheuvel.nl>, 2020",
            "Sigi 789 <ssigi333lvl3@outlook.com>, 2020",
            "Stan Overgauw <stan.overgauw@gmail.com>, 2020",
            "th p <thijs.paelman+git@hotmail.be>, 2020",
            "Anne Gerben van Assen <annegerben+transifex@vanassen.eu>, 2021",
            "Daan Breur <daanbreur@gmail.com>, 2021",
            "Gerard stn, 2021",
            "Grocy NL, 2021",
            "Jeroen Blevi <jeroen@triponoid.com>, 2021",
            "L. P. <lloyd4post11@hotmail.com>, 2021",
            "Mark Peters <forkless@gmail.com>, 2021",
            "mc bloch <transifex@mcbloch.dev>, 2021",
            "Sebastiaan Ammerlaan <steelbas@gmail.com>, 2021",
            "Luc Donderwinkel, 2022",
            "Pieter Vantorre, 2022",
            "Simon Bor <mail@simonbor.nl>, 2022",
            "T. van der Nagel, 2022",
            "Matthijs <matthijs@spamkip.com>, 2023",
            "Rutger Meekers, 2023",
            "vanhoof.tech, 2023",
            "M B, 2025",
            "ren touw, 2025",
            "Kaj Rumpff, 2026",
        ]
    )
    static let czech = Language(
        name: "Czech",
        flag: "🇨🇿",
        maintainers: "zemanl79",
        contributors: [
            "Michal Petříček <michal@petricek.org>, 2019",
            "Tomas Reznicek <tomas.reznicek@gmail.com>, 2019",
            "Adam Kroupa <mavi222@seznam.cz>, 2020",
            "Bernd Bestel <bernd@berrnd.de>, 2020",
            "Jaroslav Lichtblau <jlichtblau@seznam.cz>, 2020",
            "Jose Riha <jose1711@gmail.com>, 2020",
            "Matyas Bobek <matyas.bobek@gmail.com>, 2020",
            "Michal Franc, 2020",
            "Ondřej Suk <ondra.suk.55@gmail.com>, 2020",
            "Radim Kabeláč <radim.ekk@gmail.com>, 2020",
            "Jarda Tesar <intossh@gmail.com>, 2021",
            "Pavel Paseka, 2022",
        ]
    )
    static let italian = Language(
        name: "Italian",
        flag: "🇮🇹",
        maintainers: "mike9449",
        contributors: [
            "42d76af3cd20bc399c7e8a413695959f, 2019",
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Matteo Piotto <matteo.piotto@welaika.com>, 2019",
            "Matteo Piccina <altermatte@gmail.com>, 2021",
            "Sergio Zampello <seriotv88@gmail.com>, 2021",
            "Andrea Raineri, 2022",
            "Antonino Ursino <ninus_@libero.it>, 2022",
            "Moltivie Denied <major2015usa@gmail.com>, 2022",
            "Walter Palagi, 2022",
            "Antonio Nardella, 2023",
            "Claudio Arseni <claudio.arseni@gmail.com>, 2023",
            "Davide Casella, 2023",
            "Martino Falorni, 2023",
            "gabrieke partiti, 2024",
            "Giovanni Mascellani, 2024",
            "albanobattistella <albanobattistella@gmail.com>, 2025",
            "Saul il <ilsaul2@gmail.com>, 2025",
        ]
    )
    static let chinese_simplified = Language(
        name: "Chinese (Simplified)",
        flag: "🇨🇳",
        maintainers: "3L/404alex/WeydonDing",
        contributors: [
            "a a <akv40402@zzrgg.com>, 2020",
            "jd615645 <jd615645@gmail.com>, 2020",
            "milkfish <i@mxd.moe>, 2020",
            "文春鹏 <wcp1231@gmail.com>, 2020",
            "ba X <985096998@qq.com>, 2022",
            "Weicheng Ao, 2022",
            "Xuesong, 2022",
            "aleixcox, 2023",
            "Bernd Bestel <bernd@berrnd.de>, 2023",
            "foo bar, 2023",
            "冠南 胡, 2023",
            "石磊, 2023",
            "songhua tong <yolylight@hotmail.com>, 2025",
            "彬源 朱, 2025",
        ]
    )
    static let portuguese_PT = Language(
        name: "Portuguese (Portugal)",
        flag: "🇵🇹",
        maintainers: "otshug/Ricardo.O",
        contributors: [
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Carlos Pereira <cmp.sta@gmail.com>, 2020",
            "Miguel Pereira <miguelpereira.pro@gmail.com>, 2020",
            "Ricardo Rodrigues <fenix999@gmail.com>, 2020",
            "Francisco Norton Brandão, 2022",
            "Joao Santos <joaocpdsantos@gmail.com>, 2022",
            "Jorge Araújo, 2022",
            "João Queirós, 2022",
            "Luís Neto, 2022",
            "Cesar Veloso, 2023",
            "Joao Cabral, 2024",
        ]
    )
    static let portuguese_BR = Language(
        name: "Portuguese (Brazil)",
        flag: "🇧🇷",
        maintainers: "otshug",
        contributors: [
            "Armando Neto <armando.muassab@gmail.com>, 2019",
            "Bernd Bestel <bernd@berrnd.de>, 2019",
            "Danilo Vieira <cebikyn@gmail.com>, 2019",
            "Jefferson Brito Passos dos Santos <jeffersantoss@gmail.com>, 2019",
            "Joao Santos <joaocpdsantos@gmail.com>, 2019",
            "Andre Souto <andre.jost@gmail.com>, 2020",
            "Arthur Vieira <skytakes.arthur@gmail.com>, 2020",
            "Leonardo Fialho <leonardofialho@gmail.com>, 2020",
            "Bruno Mouta <brumouta@gmail.com>, 2021",
            "Eduardo Bizarro, 2021",
            "Jonatha Nogueira Barbosa <jb.barbosa133@gmail.com>, 2021",
            "João Filipe Cavichiolo Storrer <jofi_casto@hotmail.com>, 2021",
            "Wendell Mendes <wendellmendes@live.com>, 2021",
            "Arthur Rodrigues <transifex@araruna.me>, 2022",
            "Fernando Luiz Bonifácio de Oliveira, 2022",
            "Ryan Monteiro, 2022",
            "Webysther Sperandio <webysther@gmail.com>, 2022",
            "Anti Gona, 2023",
            "Aurelio Barreto <aurelio@aureliobarreto.com>, 2023",
            "Marcio Ota, 2023",
        ]
    )
    static let norwegian_bokmal = Language(
        name: "Norwegian Bokmål",
        flag: "🇳🇴",
        maintainers: "RonnyRusten, jonsigg",
        contributors: [
            "Andreas Henden <chairman2s.ah@gmail.com>, 2019",
            "Ruben Sperre <ruben@rsperre.net>, 2020",
            "Bernd Bestel <bernd@berrnd.de>, 2021",
            "Marius Borø <blizzwave@gmail.com>, 2021",
            "Tor Eirik Trandal <teitrand@hotmail.com>, 2021",
            "Kurt Inge Smådal, 2022",
            "Ronny Rusten, 2023",
            "Vegard Fladby <vegard.fladby@gmail.com>, 2023",
            "Kristian Daae-Johansen, 2024",
        ]
    )
    static let finnish = Language(name: "Finnish", flag: "🇫🇮", maintainers: "", contributors: [
        "Niko Granö <niko9911@ironlions.fi>, 2019",
        "oskari uusitalo <osku78@gmail.com>, 2019",
        "Bernd Bestel <bernd@berrnd.de>, 2020",
        "James Jesse <jt.inkinen@gmail.com>, 2020",
        "jarkko hämäläinen <zeik@iki.fi>, 2020",
        "Jukka-Pekka Kokkonen <jukkapekka.kokkonen@gmail.com>, 2020",
        "Kalle Laakso <rogueshadow@keemail.me>, 2020",
        "Matias Käkelä <matias.kakela@gmail.com>, 2020",
        "Tuomas Yrjölä <yrski@pm.me>, 2020",
        "Lauri Niskanen <ape3000@gmail.com>, 2021",
        "Matti Koskimies <matti@apulanta.fi>, 2021",
        "'t <trajahan@gmail.com>, 2022",
        "Markus Laaksonen, 2022",
        "Sami Kiviniemi, 2024",
        "Tomi H, 2025",
    ])
    static let japanese = Language(name: "Japanese", flag: "🇯🇵", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2020",
        "Cisco Benjamin <metallica@vivaldi.net>, 2020",
        "EbXpJ6bp <ebxpj6bp@outlook.jp>, 2020",
        "KATSUHIKO SHIGEYAMA <kshigeyama@gmail.com>, 2020",
        "Tatsuya Ueda <ml@tatsuya.info>, 2020",
        "鳥山 陽平 <kagemomiji@gmail.com>, 2022",
        "Takuya Mizuguchi, 2024",
        "pigmentblue15, 2025",
        "Taiki Matsumura, 2025",
    ])
    static let ukrainian = Language(name: "Ukrainian", flag: "🇺🇦", maintainers: "", contributors: [
        "Ivan Gavryliuk <igavryliuk@solusvm.com>, 2020",
        "Oleksii Filonenko <brightone@protonmail.com>, 2020",
        "NazimUa <nazim-ua@ukr.net>, 2021",
        "Aleksey Zaremskiy, 2022",
        "Bernd Bestel <bernd@berrnd.de>, 2022",
    ])
    static let catalan = Language(name: "Catalan", flag: "🏴󠁥󠁳󠁣󠁴󠁿", maintainers: "", contributors: [
        "Joan Rodas <joanrc93@gmail.com>, 2020",
        "Carles Riera <blauigris@gmail.com>, 2021",
        "gimy16 <gimy16@hotmail.com>, 2021",
        "Bernd Bestel <bernd@berrnd.de>, 2022",
        "jorclaret, 2022",
        "Martí Gombau, 2023",
        "Auri, 2024",
        "Pau Nofuentes Sendra, 2024",
        "Roger Solé Vilajuliu, 2024",
    ])
    static let greek = Language(name: "Greek", flag: "🇬🇷", maintainers: "", contributors: [
        "datablitz7 <plant7@gmail.com>, 2019",
        "ByteGet, 2020",
        "Dionysios Gkotsis <bloodsak4@yahoo.gr>, 2020",
        "Stathis Stamoulis <sstamoulis2010@gmail.com>, 2020",
        "Thodoris Kalatzis <teo.kal@hotmail.com>, 2021",
        "Bernd Bestel <bernd@berrnd.de>, 2022",
        "Dimitris, 2022",
        "emmker kats, 2022",
        "Lefteris Garyfalakis, 2022",
        "Vasilis Mourtzis, 2023",
    ])
    static let britishEnglish = Language(name: "English (United Kingdom)", flag: "🇬🇧", maintainers: "", contributors: [
        "Ben Fayers <ben.fayers@gmail.com>, 2020",
        "duck. <me@duck.me.uk>, 2020",
        "John Coles <john@johncoles.com>, 2020",
        "Jonathan Adams <jonathan@connockadams.uk>, 2020",
        "Chris H <cjh861@outlook.com>, 2021",
        "David Knapman <dai.knapz@gmail.com>, 2021",
        "w ralb <g.frcy.trnsfx@barlowhome.org>, 2021",
        "Johnnie Blows, 2022",
        "George Aston, 2024",
        "Andi Chandler <andi@gowling.com>, 2025",
    ])
    static let estonian = Language(name: "Estonian", flag: "🇪🇪", maintainers: "", contributors: [
        "Mario Loik <mariomobla@gmail.com>, 2020",
        "aylamz, 2023",
        "Bernd Bestel <bernd@berrnd.de>, 2023",
        "Lauri Lepik, 2023",
    ])
    static let hebrew = Language(name: "Hebrew", flag: "🇮🇱", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2019",
        "Adi Zarko <kapkapon@gmail.com>, 2020",
        "Netanel Lazarovich <natylaza89@gmail.com>, 2020",
        "רון יצחקי <ronveofir@gmail.com>, 2020",
        "Yaron Shahrabani <sh.yaron@gmail.com>, 2025",
    ])
    static let korean = Language(name: "Korean", flag: "🇰🇷", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2020",
        "신강수 <idaksha@outlook.com>, 2020",
        "CW kim <cw2002.kim@gmail.com>, 2021",
        "Junsu Jeong, 2023",
        "YS Lee, 2024",
    ])
    static let romanian = Language(name: "Romanian", flag: "🇷🇴", maintainers: "", contributors: [
        "Stefan Petrea <stefan@garage-coding.com>, 2020",
        "Pwnisher <ciprian420@gmail.com>, 2021",
        "Adi B, 2022",
        "Gabriel Andreescu <gabone01@gmail.com>, 2022",
        "Marian-Bogdan Muntean, 2022",
        "Mădălin Pătrăşcanu <mada.patrascanu@gmail.com>, 2022",
        "rathantara Tase, 2022",
        "Bernd Bestel <bernd@berrnd.de>, 2023",
        "Dorin JOREA <dorin.jorea@gmail.com>, 2023",
    ])
    static let slovak = Language(name: "Slovak", flag: "🇸🇰", maintainers: "", contributors: [
        "Marko Zbirka <illethrias@gmail.com>, 2019",
        "Juraj Smieško <juraj.smiesko@gmail.com>, 2020",
        "peter cerny <posli.to.semka@gmail.com>, 2020",
        "Bernd Bestel <bernd@berrnd.de>, 2022",
        "Miroslav Ďurian, 2022",
        "Jose Riha <jose1711@gmail.com>, 2023",
    ])
    static let slovenian = Language(name: "Slovenian", flag: "🇸🇮", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2022",
        "bostjo g, 2022",
        "Anže Pintar <anze.pintar2@gmail.com>, 2023",
        "David Koprivec, 2024",
        "Žiga Bobnar, 2025",
    ])
    static let turkish = Language(name: "Turkish", flag: "🇹🇷", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2019",
        "Tuğberk Kaan Duman <kaan@dumanmail.com>, 2019",
        "Yigit Sever <yigit@ceng.metu.edu.tr>, 2021",
        "Sedat Mehmed, 2022",
        "Burak ER, 2023",
        "Bora Atıcı, 2025",
    ])
    static let lithuanian = Language(name: "Lithuanian", flag: "🇱🇹", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2022",
        "Vytautas Barkauskas, 2023",
    ])
    static let tamil = Language(name: "Tamil", flag: "🇮🇳", maintainers: "", contributors: [
        "Sathish K <sathishkk@sathishkumark.com>, 2019",
        "Aswin Kumar, 2022",
        "Bernd Bestel <bernd@berrnd.de>, 2022",
    ])
    static let spanish = Language(name: "Spanish", flag: "🇪🇸", maintainers: "", contributors: [
        "Ankue <ankue.spam@gmail.com>, 2019",
        "Bernd Bestel <bernd@berrnd.de>, 2019",
        "Fernando Sánchez <fernando.l.sanchez@gmail.com>, 2019",
        "Alan Pucheta <apucheta@protonmail.com>, 2020",
        "Christian Cotillas <marril01@gmail.com>, 2020",
        "Enrique Lapenta <enriquelap20@gmail.com>, 2020",
        "Igor Perez <igordiablo@hotmail.com>, 2020",
        "José Rugel <joserugel@gmail.com>, 2020",
        "Adrián R.G. <adrirgrillo@gmail.com>, 2021",
        "Alberto Martin <ami232@gmail.com>, 2021",
        "Juan José González-Abril, 2021",
        "victormce <victormce@gmail.com>, 2021",
        "GRBaset, 2022",
        "Matt Sawyers, 2022",
        "Jose Manuel Ruiz, 2023",
        "Ricardo Verduguez, 2023",
        "Pier Jose Gotta Perez <piegope@protonmail.com>, 2024",
    ])
    static let danish = Language(name: "Danish", flag: "🇩🇰", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2019",
        "Brian Moos Lindberg <brian@blueeel.dk>, 2019",
        "dark159123 <r.j.hansen@protonmail.com>, 2019",
        "Rasmus Bojsen <rasmus@bojsen.cn>, 2019",
        "Troels Siggaard <troels@siggaard.com>, 2019",
        "Mihai Marinescu <mihai@marinescu.dk>, 2020",
        "Jesper Donnis, 2021",
        "Kim Bardrum <kim.bardrum@gmail.com>, 2021",
        "klavslund <klavslund@gmail.com>, 2021",
        "Michael Winkel <mbw@mbw.dk>, 2021",
        "hskdk <henrik@skjaerbaek.net>, 2023",
        "Tobias Østergaard-Jørgensen, 2023",
        "G Momsen, 2024",
        "eurosite, 2025",
    ])
    static let hungarian = Language(name: "Hungarian", flag: "🇭🇺", maintainers: "", contributors: [
        "Márk Kökény <oregapamgroup@gmail.com>, 2019",
        "Richard Szolár <szolar.richard@gmail.com>, 2019",
        "Ádám Kovács <kovacsadam07@outlook.hu>, 2019",
        "Bernd Bestel <bernd@berrnd.de>, 2020",
        "bolash <balazs.izso@gesundheitscloud.de>, 2020",
        "Gabor Pilsits <gabor.pilsits@gmail.com>, 2020",
        "Gábor Szellő <gabor.szello@gmail.com>, 2020",
        "lakosd <login@lakosd.net>, 2020",
        "Peter Gyetvai <gyetpet@mailbox.org>, 2021",
        "Tallyrald, 2021",
        "Vad Laszlo, 2021",
        "Andras B, 2022",
        "rozgonik <rozgonik1@gmail.com>, 2023",
        "Tamas Voros <voros.e.tamas@gmail.com>, 2023",
        "Gergő Mihály, 2025",
        "Gábor Buslig, 2025",
    ])
    static let swedish = Language(name: "Swedish", flag: "🇸🇪", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2019",
        "Fredrik Hendeberg <fredrik@hendeberg.com>, 2019",
        "Jesper Sandström <jesper@languageconsulting.se>, 2019",
        "Jimmy Hawkin <jimmyhawkin@gmail.com>, 2019",
        "Mathias Fröjd <info@mcfrojd.com>, 2019",
        "Peter Wickenberg <peter@wickenberg.nu>, 2019",
        "A A <transifex@stardestroyer.se>, 2020",
        "Andreas Olsson <basen82@protonmail.com>, 2020",
        "namob <boman.d@gmail.com>, 2020",
        "Per Bäckman <fotodille@gmail.com>, 2020",
        "Sebastian Backman <valtkor@hotmail.com>, 2020",
        "Eduard Kapoun, 2022",
        "Matt Sawyers, 2022",
        "Robert Johansson, 2022",
        "Eric Andersson, 2023",
        "riiga <riiga_92@hotmail.com>, 2024",
        "Jesper, 2025",
        "Johan Helin, 2025",
    ])
    static let chinese_traditional = Language(name: "Chinese (Traditional)", flag: "🇹🇼", maintainers: "", contributors: [
        "Bernd Bestel <bernd@berrnd.de>, 2020",
        "jd615645 <jd615645@gmail.com>, 2020",
        "ppatrickxctw <ppatrickxctw@gmail.com>, 2020",
        "richegg Tsai <zxp86021@gmail.com>, 2020",
        "鍾佑豪 <zobuwei@gmail.com>, 2020",
        "alexli1205, 2022",
        "NelsonSu, 2026",
    ])
    static let languages: Set<Language> = [english, german, french, polish, dutch, czech, italian, chinese_simplified, portuguese_PT, portuguese_BR, norwegian_bokmal, finnish, japanese, ukrainian, catalan, greek, britishEnglish, estonian, hebrew, korean, romanian, slovak, slovenian, turkish, lithuanian, tamil, spanish, danish, hungarian, swedish, chinese_traditional]
}
