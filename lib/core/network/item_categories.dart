class ItemCategories {
  ItemCategories._();

  static const List<String> categoryOrder = [
    'BRANDED',
    'NOTEBOOK',
    'KOMPONEN',
    'CTRD TINTA TONER',
    'PRINTER SCANNER',
    'PROJEKTOR',
    'UPS',
    'HP TAB',
    'MONITOR',
    'AKSESORIS',
    'LAIN-LAIN',
  ];

  static const Map<String, String> subToParent = {
    // BRANDED
    'PCAIO': 'BRANDED',
    'PCBU': 'BRANDED',
    'PCMINI': 'BRANDED',
    'PCMN': 'BRANDED',
    'PCSVR': 'BRANDED',

    // NOTEBOOK
    'NB': 'NOTEBOOK',

    // KOMPONEN
    'PROC': 'KOMPONEN',
    'MB': 'KOMPONEN',
    'VGA': 'KOMPONEN',
    'RAM': 'KOMPONEN',
    'SSD': 'KOMPONEN',
    'SSDEX': 'KOMPONEN',
    'HDIN3': 'KOMPONEN',
    'HDIN2': 'KOMPONEN',
    'HDEX2': 'KOMPONEN',
    'HDEX3': 'KOMPONEN', // Added back as it was in the dashboard image
    'CS': 'KOMPONEN',
    'PSU': 'KOMPONEN',
    'CLR': 'KOMPONEN',
    'FAN': 'KOMPONEN',

    // CTRD TINTA TONER
    'TINTA': 'CTRD TINTA TONER',
    'CARTD': 'CTRD TINTA TONER',

    // PRINTER SCANNER
    'PRINT': 'PRINTER SCANNER',
    'SCAN': 'PRINTER SCANNER',

    // PROJEKTOR
    'PJT': 'PROJEKTOR',

    // UPS
    'UPS': 'UPS',

    // HP TAB
    'HPTB': 'HP TAB',

    // MONITOR
    'LCD': 'MONITOR',

    // AKSESORIS
    '2ND': 'AKSESORIS',
    'ACS': 'AKSESORIS',
    'ADP': 'AKSESORIS',
    'AL': 'AKSESORIS',
    'ATK': 'AKSESORIS',
    'BAT': 'AKSESORIS',
    'BRKT': 'AKSESORIS',
    'CCTV': 'AKSESORIS',
    'DRW': 'AKSESORIS',
    'GMC': 'AKSESORIS',
    'HEL': 'AKSESORIS',
    'KAS': 'AKSESORIS',
    'KB': 'AKSESORIS',
    'KBL': 'AKSESORIS',
    'KBM': 'AKSESORIS',
    'MC': 'AKSESORIS',
    'MDM': 'AKSESORIS',
    'MJ': 'AKSESORIS',
    'MM': 'AKSESORIS',
    'MS': 'AKSESORIS',
    'NWK': 'AKSESORIS',
    'PP': 'AKSESORIS',
    'RCK': 'AKSESORIS',
    'SOFT': 'AKSESORIS',
    'SP': 'AKSESORIS',
    'STAB': 'AKSESORIS',
    'TP': 'AKSESORIS',
    'TPOD': 'AKSESORIS',
    'UFD': 'AKSESORIS',
  };

  static const Map<String, List<String>> subCategoryOrder = {
    'BRANDED': ['PCAIO', 'PCBU', 'PCMINI', 'PCMN', 'PCSVR'],
    'NOTEBOOK': ['NB'],
    'KOMPONEN': [
      'PROC',
      'PSU',
      'RAM',
      'HDEX2',
      'HDIN2',
      'HDEX3',
      'HDIN3',
      'SSD',
      'SSDEX',
      'VGA',
      'CLR',
      'FAN',
      'CS',
      'MB'
    ],
    'CTRD TINTA TONER': ['TINTA', 'CARTD'],
    'PRINTER SCANNER': ['PRINT', 'SCAN'],
    'PROJEKTOR': ['PJT'],
    'UPS': ['UPS'],
    'HP TAB': ['HPTB'],
    'MONITOR': ['LCD'],
    'AKSESORIS': [
      '2ND',
      'ACS',
      'ADP',
      'AL',
      'ATK',
      'BAT',
      'BRKT',
      'CCTV',
      'DRW',
      'GMC',
      'HEL',
      'KAS',
      'KB',
      'KBL',
      'KBM',
      'MC',
      'MDM',
      'MJ',
      'MM',
      'MS',
      'NWK',
      'PP',
      'RCK',
      'SOFT',
      'SP',
      'STAB',
      'TP',
      'TPOD',
      'UFD'
    ],
  };

  static const Map<String, String> displayNames = {
    'BRANDED': 'BRANDED',
    'PCAIO': 'PCAIO',
    'PCBU': 'PCBU',
    'PCMINI': 'PCMINI',
    'PCMN': 'PCMN',
    'PCSVR': 'PCSVR',
    'NOTEBOOK': 'NOTEBOOK',
    'NB': 'NB',
    'KOMPONEN': 'KOMPONEN',
    'PROC': 'PROC',
    'MB': 'MB',
    'VGA': 'VGA',
    'RAM': 'RAM',
    'SSD': 'SSD',
    'SSDEX': 'SSDEX',
    'HDIN3': 'HDIN3',
    'HDIN2': 'HDIN2',
    'HDEX2': 'HDEX2',
    'HDEX3': 'HDEX3',
    'CS': 'CS',
    'PSU': 'PSU',
    'CLR': 'CLR',
    'FAN': 'FAN',
    'CTRD TINTA TONER': 'CTRD TINTA TONER',
    'TINTA': 'TINTA',
    'CARTD': 'CARTD',
    'PRINTER SCANNER': 'PRINTER SCANNER',
    'PRINT': 'PRINT',
    'SCAN': 'SCAN',
    'PROJEKTOR': 'PROJEKTOR',
    'PJT': 'PJT',
    'UPS': 'UPS',
    'HP TAB': 'HP TAB',
    'HPTB': 'HPTB',
    'MONITOR': 'MONITOR',
    'LCD': 'LCD',
    'AKSESORIS': 'AKSESORIS',
    '2ND': '2ND',
    'ACS': 'ACS',
    'ADP': 'ADP',
    'AL': 'AL',
    'ATK': 'ATK',
    'BAT': 'BAT',
    'BRKT': 'BRKT',
    'CCTV': 'CCTV',
    'DRW': 'DRW',
    'GMC': 'GMC',
    'HEL': 'HEL',
    'KAS': 'KAS',
    'KB': 'KB',
    'KBL': 'KBL',
    'KBM': 'KBM',
    'MC': 'MC',
    'MDM': 'MDM',
    'MJ': 'MJ',
    'MM': 'MM',
    'MS': 'MS',
    'NWK': 'NWK',
    'PP': 'PP',
    'RCK': 'RCK',
    'SOFT': 'SOFT',
    'SP': 'SP',
    'STAB': 'STAB',
    'TP': 'TP',
    'TPOD': 'TPOD',
    'UFD': 'UFD',
  };

  static List<String> getAllCategoryCodes() {
    return displayNames.keys.toList();
  }

  static String getDisplayName(String code) {
    if (code.isEmpty) return code;
    return displayNames[code.toUpperCase()] ?? code;
  }
}
