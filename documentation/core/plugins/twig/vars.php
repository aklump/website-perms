<?php
/**
 * @file
 * Parses Drupal's Advanced Help .ini file and creates page var .kit variables
 *
 * @ingroup loft_docs
 * @{
 */

use AKlump\Data\Data;
use AKlump\LoftDocs\PageMetaData;
use AKlump\LoftDocs\OutlineJson as Index;
use AKlump\LoftLib\Storage\FilePath;
use Ckr\Util\ArrayMerger;

$CORE = getenv('LOFT_DOCS_CORE');
require_once $CORE . '/vendor/autoload.php';

list(, $outline_file, $page_id, $version) = $argv;

$data_provider = new PageMetaData([
  "$CORE/../source",
  getenv('LOFT_DOCS_CACHE_DIR') . '/source',
]);
$page_frontmatter = $data_provider->setPageId($page_id)->get();

$data_file = getenv('LOFT_DOCS_CACHE_DIR') . '/page_data.json';
$page_data = file_exists($data_file) ? json_decode(file_get_contents($data_file), TRUE) : array();
$page_data[$page_id] = ArrayMerger::doMerge($page_frontmatter, $page_data[$page_id] ?? []);

$vars = array(
  'version' => $version,
  'classes' => array(),
  'meta' => $page_frontmatter,

  // @deprecated; use meta instead.
  'page' => $page_data[$page_id],
);

$g = new Data();
$index = new Index($outline_file);

$vars['index'] = array();
foreach ($index->getData() as $key => $value) {
  // Skip a self reference
  if (in_array($key, array('index', 'search--results'))) {
    continue;
  }
  $vars['index'][] = $value;
}

if (($data = $index->getData()) && isset($data[$page_id])) {
  $vars += $data[$page_id];
  $vars['classes'] = array('page--' . $vars['id']);
}

// Ensure these default vars
$g->ensure($vars, 'title', '');
$g->ensure($vars, 'prev', 'javascript:void(0)');
$g->ensure($vars, 'prev_id', '');
$g->ensure($vars, 'prev_title', '');
$g->ensure($vars, 'next', 'javascript:void(0)');
$g->ensure($vars, 'next_id', '');
$g->ensure($vars, 'next_title', '');
$vars['chapters'] = $index->getChapterIndex();

$outline_data = json_decode(file_get_contents($outline_file), TRUE);
$vars['book'] = [
  'title' => $g->get($outline_data, 'title'),
  'total_chapters' => count($vars['chapters']),
  'total_pages' => count($vars['index']),
];

// Add in additional vars:
$now = new \DateTime('now', new \DateTimeZone('America/Los_Angeles'));
$vars['date'] = $vars['date'] ?? $now->format('r');

// Search support.
$outline = FilePath::create($outline_file)->load()->getJson(TRUE);
$g->onlyIf($outline, 'settings.search')->set($vars, 'search', TRUE);

$json = json_encode($vars);
print $json;
