# frozen_string_literal: true

class RunestonesHelper
  RunestoneTemplate = Struct.new(:id, :name, :author, :text)
  @runestones = []

  def self.add(id, name, author, text)
    raise ArgumentError, "Runestone with ID #{id} already exists!" if exists?(id)

    @runestones << RunestoneTemplate.new(id, name, author, text)
  end

  def self.all
    @runestones
  end

  def self.count
    @runestones.length
  end

  def self.first
    @runestones.first
  end

  def self.find(id)
    @runestones.find { |runestone| runestone.id == id }
  end

  def self.exists?(id)
    @runestones.any? { |runestone| runestone.id == id }
  end
end

RunestonesHelper.add(
  'elements',
  'Runestone of the Elements',
  'Unknown',
  'Bound within the essence of the elements, the greatest alchemical formula lies hidden. It speaks of a harmony, a perfect balance where matter and energy converge. Seek the components that dance to the ancient rhythms of the earth, air, fire, and water. Combine them with wisdom and respect, for their power is not to be wielded lightly. In their union, discover the secrets that can bend reality, transcend the ordinary, and unveil the extraordinary.',
)
RunestonesHelper.add(
  'alchemy',
  'Runestone of Alchemy',
'Master Alchemist Galen',
  'In the crucible of stars and earth, alchemy weaves its silent song. From the marriage of elements, secrets are born, unlocking the doors to transformation. Ancient formulas hidden in the shadows of the mundane, where the mundane becomes miraculous. But beware, for in the pursuit of alchemical mastery, the line between creation and destruction is thin, bound by laws unforgiving as the chasm\'s edge.',
)
RunestonesHelper.add(
  'ancient_battle',
  'Runestone of Ancient Battle',
  'Unknown',
  'Upon this stone is etched the saga of a battle timeless, where steel and sinew met flame and scale in a dance of war. The Mechanists, masters of iron and gear, stood with their creations - the sentinel automata - in a display of formidable ingenuity. Across the field, the enemy army bolstered with dragons of ancient might, their breaths weaving fire that turned metal to molten rivers. The sky roared with the clash of man, machine, and draconic fury, ballista bolts piercing the heavens to meet winged behemoths. A maelstrom of destruction swept the land, a testament to the prowess and valor of both sides. Victory was claimed by the Mechanists, their glory etched in history, yet this stone honors all who fell, for in their sacrifice lies the true epic of battle. Let it stand as a monument to the courage that flowed like rivers of steel and fire, a tribute to the indomitable spirit that defies even the darkest of hours.',
)
RunestonesHelper.add(
  'automata',
  'Runestone of Automata',
'Unknown',
  'In this era of boundless ingenuity, we have wrought wonders from metal and steam. Our creations walk amongst us, embodiments of our highest aspirations. Each construct, from the humblest laborer to the grandest sentinel, bears the mark of our mastery over the mechanical arts. We have forged our way to harmony. In this age, our creations serve and enhance the tapestry of life, a testament to the potential for unity between creation and creator. This stone commemorates the pinnacle of prosperity, a reminder of what can be achieved when innovation is guided by wisdom and purpose.',
)
RunestonesHelper.add(
  'elemental_power',
  'Runestone of Elemental Power',
  'Unknown',
  'Elements converge where the earth\'s heartbeat is strongest. Speak the ancient words where fire, water, earth, and air unite, and harness the primal forces that bind the world. In the dance of creation and destruction, find your power.',
)
RunestonesHelper.add(
  'ley_lines',
  'Runestone of Ley Lines',
  'Unknown',
  'Born from the heart of the cataclysm, a new force emerged. Unseen streams, where magic breathes and pulses, weave through the land like whispers of forgotten tales. Here, where the earth sings with unseen power, we stand at the threshold of the unknown. May those who seek their paths tread with reverence.',
)
RunestonesHelper.add(
  'lycanthropy',
  'Runestone of Lycanthropy',
'Unknown',
  'In the shadowed realms of our world, a curse ancient and wild stirs. It binds man to beast, a duality of spirit wrought in moon\'s light. The afflicted roam, tormented by a nature not their own, seeking solace yet finding none. Yet within the darkness lies a glimmer of hope - the Nightshade flower, blooming under the full moon\'s embrace. Its petals hold the key to breaking the fevered transformation, a remedy forged in nature\'s own hand. Seek the Nightshade in the groves where moonlight dances, and let its essence restore what was torn asunder.',
)
RunestonesHelper.add(
  'preservation',
  'Runestone of Preservation',
  'Unknown',
  'Hear the ancient call of the groves, the sacred duty to protect. The roots of the past entwine with the seeds of the future, growing a sanctuary for all.',
)
RunestonesHelper.add(
  'promise',
  'Runestone of Promise',
'Unknown',
  'As the stars guide the night, so shall we illuminate the path. In balance, find harmony; in light, find hope. Our vigil shall not wane.',
)
RunestonesHelper.add(
  'reclamation',
  'Runestone of Reclamation',
  'Unknown',
  'After the skies cleared from the Seven Days of Fire, from the ashes rose a new resolve. The world, scarred yet unbowed, was embraced by those who survived. In the ruins of the old, foundations for the new were laid. Cities reborn atop remnants, nature reclaiming its ruptured realms, and races uniting under the banner of hope and resilience. This stone stands as a testament to our unyielding spirit, to the courage that forged paths through desolation, and to the unwavering belief that even in the wake of devastation, life finds a way to blossom anew.',
)
RunestonesHelper.add(
  'resilience',
  'Runestone of Resilience',
'Unknown',
  'In the aftermath of fire, we found resilience. Let this stone serve as a testament to our endurance and the unbreakable spirit of those who safeguard the balance.',
)
RunestonesHelper.add(
  'ancient_guardians',
  'Runestone of the Ancient Guardians',
  'High Luminary Aurelius',
  'Beneath the starlit sky, we stood, our vows to balance and light we pledged. Seek the hidden paths where celestial songs align, and the secrets of the cosmos shall be our guide. The celestial paths will illuminate our destiny.',
)
RunestonesHelper.add(
  'arcane_nexus',
  'Runestone of the Arcane Nexus',
'Magister Nocturnus',
  'At the crossroads of invisible lines, power lies dormant, waiting to be awakened. He who masters the ley lines\' conflux shall wield the arcane\'s true potential.',
)
RunestonesHelper.add(
  'astral_seeker',
  'Runestone of the Astral Seeker',
  'Unknown',
  'Look to the heavens when lost, for the constellations hold stories of old. Each star a guide, each constellation a chapter in the saga of the cosmos.',
)
RunestonesHelper.add(
  'forest',
  'Runestone of the Forest',
'Unknown',
  'This stone stands as a testament to the boundless grace of the forest, the heart of nature\'s untamed splendor. In its shadow, trees tower like ancient sentinels, their leaves whispering the secrets of the wild. Beneath their canopy, a symphony of life plays out in endless cycles of growth and renewal. Here, in the verdant embrace of the woods, one finds the essence of life itself, intertwined roots and branches forming a sanctuary of tranquility and strength. Let this stone remind all who pass by of the forest\'s enduring beauty, a monument to the interwoven tapestry of life that flourishes beneath the watchful gaze of the green.',
)
RunestonesHelper.add(
  'forgotten_lore',
  'Runestone of the Forgotten Lore',
  'Unknown',
  'In forgotten lore lies hidden truths, lived by those those who witnessed the world\'s turning. Seek out tales lost to time, secrets of the ancients that echo through the ages. In history\'s shadow, find the light of understanding.',
)
RunestonesHelper.add(
  'hope',
  'Runestone of Hope',
  'Unknown',
  'From the ashes of despair, hope can be reborn. In the remnants of a catastrophe lies the seed of new beginnings. Seek the echoes of a past long gone, and learn from the tales of yore.',
)
RunestonesHelper.add(
  'lost_traveller',
  'Runestone of the Lost Traveller',
'Unknown',
  'To those who wander, seek not just the destination but cherish the journey. Each step on this land holds a story, a lesson from those who walked before.',
)
RunestonesHelper.add(
  'legacy',
  'Runestone of Legacy',
  'Unknown',
  'Where gears and dreams entwine, the legacy of our hands remains. Follow the path of the lost tinkerer to discover creations that time forgot, in a place where thought becomes reality.',
)
RunestonesHelper.add(
  'warning',
  'Runestone of Warning',
'Unknown',
  'Beware the hubris of creation, for in our quest to play gods, we birthed our own downfall. Let not the allure of ultimate power blind you as it did us.',
)
RunestonesHelper.add(
  'omega',
  'Runestone of the Omega',
  'Unknown',
  'In the zenith of our craft, we dreamt of a device to end all wars, a creation born of mechanical prowess and the alchemical unknown. The Omega, our ambition\'s child, remained incomplete, its heart silent. Yet, its shadow loomed large, a harbinger of the cataclysm to come. Within the ruins of our pride, among the whispers of the lost, lies the echo of its promise and peril. Let those who seek the fragments of the Omega tread with caution, for its tale is one of brilliance overshadowed by the darkest of follies.',
)
RunestonesHelper.add(
  'seven_days_of_fire',
  'Runestone of the Seven Days of Fire',
  'Unknown',
  'This stone stands in solemn tribute to the souls lost during the Seven Days of Fire, when the world was engulfed by an inferno beyond imagination. Skies alight with sorrow, lands rendered barren in mourning, and seas that wept in steam – all bear witness to the loss endured. It was not merely the earth that was scorched, but the very fabric of life itself. We inscribe their memory upon this stone, not just as a record of devastation, but as a homage to the resilience of spirit and the hope that blossoms even in the heart of despair. May their legacy guide us in forging a world where such a calamity is never revisited.',
)
RunestonesHelper.add(
  'starborne',
  'Runestone of the Starborne',
'Astral Scholar Lunara',
  'From the celestial heavens, the Starborne send their wisdom. When the stars align and night\'s curtain is drawn, the celestial map shall reveal its truth. Follow the heavens\' guidance to uncover treasures that gleam like constellations in the night.',
)
RunestonesHelper.add(
  'timeless',
  'Runestone of the Timeless',
  'Unknown',
  'Time is both a river and a cycle, ever-flowing, ever-returning. Seek the places where time\'s fabric thins, and witness the eternal dance of moments past, present, and future. Let the ebb and flow of centuries guide your journey through the tapestry of time.',
)
RunestonesHelper.add(
  'verdant',
  'Runestone of the Verdant',
  'Unknown',
  'Hear the whispers of the ancient forests, the rustle of leaves telling tales of old. The Verdant\'s spirit is etched in stone, a testament to the deep roots and the soaring canopies. Seek harmony with nature, and let the lifeblood of the earth flow through you.',
)
RunestonesHelper.add(
  'cataclysm',
  'Runestone of the Cataclysm',
  'Unknown',
  'Heed the whispers of time, for they carry warnings from the shadows of history. Let not the arrogance of power nor the blindness of ambition lead you astray. Remember the cataclysm that once was, and guard against the seeds of your own undoing.',
)
RunestonesHelper.add(
  'cautionary_tale',
  'Runestone of the Cautionary Tale',
'Unknown',
  'Amongst the ashes of folly, the echoes of fire whisper a cautionary tale. Let the scorched earth be a testament to the ruin wrought by unchecked ambition. Beware, lest your flame of desire ignites a second inferno, consuming all in its wake.',
)
RunestonesHelper.add(
  'remembrance',
  'Runestone of Remembrance',
  'Unknown',
  'In the days when the world burned, a lesson was etched in the very essence of existence. Remember the inferno that once devoured horizons, a grim reminder of what awaits when the balance is shattered. Guard now against the sparks of ruin, for the world teeters ever close to another conflagration.',
)
RunestonesHelper.add(
  'ooze',
  'Runestone of Alchemical Creations',
'Unknown',
  'Beneath this ground, remnants of ambition flow. Tread carefully, for the alchemical creations still hunger, a lingering curse of the Mechanists\' folly.',
)
RunestonesHelper.add(
  'macaria',
  'Runestone of Macaria',
  'Unknown',
  'This stone is dedicated to the hero that restored our lands from blight. Macaria of the Vale, let her name be forever known.',
)
RunestonesHelper.add(
  'broken',
  'Broken Runestone',
  'Unknown',
  'In...  river that lies beyond... dark... Only the... talons... armor of... else to hear... control... five',
)
