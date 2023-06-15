library(webshot)
library(htmlwidgets)
library(rsvg)




# presentation ------------------------------------------------------------
(plot_hydrographs(scenehydros, gaugefilter = c('412002', '421001'),
                  colors = scene_pal) +
   theme_werp_toolkit(base_size = 10,
                      legend.position = 'bottom',
                      axis.text.x = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)", 'hydros.png'), width = 12, height = 6, units = 'cm', bg = 'transparent')

(map_example +
    theme_werp_toolkit(base_size = 10,
                       legend.position = 'bottom',
                       axis.text.x = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)", 'map_example.png'), width = 12, height = 8, units = 'cm', bg = 'transparent')

(catchcompare +
    theme_werp_toolkit(base_size = 10)) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)", 'catchbars.png'), width = 12, height = 8, units = 'cm', bg = 'transparent')


(objective_comp +
  theme_werp_toolkit(base_size = 18,
                     legend.position = 'bottom',
                     axis.text.x = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)", 'objective_comp.png'), width = 13, height = 7, units = 'cm', bg = 'transparent')

(objective_comp +
    theme_werp_toolkit(base_size = 10,
                       legend.position = 'bottom',
                       axis.text.x = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)", 'objective_comp.png'), width = 12, height = 6, units = 'cm', bg = 'transparent')



# Networks ----------------------------------------------------------------

aggNetworkbase %>% DiagrammeR::export_graph(file_name = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)",
                                                                  'network_base.png'),
                                            width = 16*300/2.54,
                                            height = 16*300/2.54)

aggNetworkdown %>% DiagrammeR::export_graph(file_name = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)",
                                                                  'network_down.png'),
                                            width = 16*300/2.54,
                                            height = 16*300/2.54)

aggNetworkup %>% DiagrammeR::export_graph(file_name = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)",
                                                                'network_up.png'),
                                          width = 16*300/2.54,
                                          height = 16*300/2.54)



# lines -------------------------------------------------------------------

line_example <-   obj_sdl_to_plot |>
  dplyr::filter(env_group %in% c('EF', 'NF', 'NV')) %>%
  plot_outcomes(y_col = 'ewr_achieved',
                x_col = 'delta',
                y_lab = 'Proportion met',
                x_lab = 'Change in flow',
                transx = 'log10',
                color_lab = 'Catchment',
                colorgroups = NULL,
                colorset = 'SWSDLName',
                point_group = 'env_obj',
                pal_list = list('calecopal::lake'),
                facet_row = 'env_group',
                facet_col = '.',
                scene_pal = scene_pal,
                sceneorder = c('down4', 'base', 'up4'),
                base_lev = 'base',
                comp_fun = 'relative',
                transy = 'pseudo_log',
                group_cols = c('env_obj', 'polyID'),
                smooth = TRUE)
(line_example +
    guides(shape = 'none') +
   theme_werp_toolkit(base_size = 18,
                      axis.text.x = element_blank(),
                      legend.position = 'none')) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)",
                                'line_example.png'),
           width = 13, height = 9, units = 'cm', bg = 'transparent')

(line_example +
    guides(shape = 'none') +
    theme_werp_toolkit(base_size = 10,
                       axis.text.x = element_blank(),
                       legend.position = 'none')) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)",
                              'line_example.png'),
         width = 9, height = 6, units = 'cm', bg = 'transparent')

line_ex2 <- obj_sdl_to_plot |>
  dplyr::filter(env_group %in% c('EF', 'NF', 'NV')) %>%
  plot_outcomes(y_col = 'ewr_achieved',
                x_col = 'delta',
                y_lab = 'Proportion met',
                x_lab = 'Change in flow',
                transx = 'log10',
                transy = 'log10',
                color_lab = 'SDL unit',
                colorset = 'SWSDLName',
                pal_list = list("calecopal::lake"),
                facet_wrapper = 'env_group',
                scene_pal = scene_pal,
                sceneorder = c('down4', 'base', 'up4'),
                base_lev = 'base',
                comp_fun = 'relative',
                add_eps = min(obj_sdl_to_plot$ewr_achieved[obj_sdl_to_plot$ewr_achieved > 0],
                              na.rm = TRUE)/2,
                group_cols = c('env_obj', 'polyID'),
                smooth = TRUE)

(line_ex2 +
    guides(shape = 'none') +
    theme_werp_toolkit(base_size = 18,
                       axis.text.x = element_blank(),
                       legend.position = 'none')) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)",
                              'line_ex2.png'),
         width = 13, height = 9, units = 'cm', bg = 'transparent')

(line_ex2 +
    guides(shape = 'none') +
    theme_werp_toolkit(base_size = 10,
                       axis.text.x = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)",
                              'line_ex2.png'),
         width = 9, height = 6, units = 'cm', bg = 'transparent')

# maps --------------------------------------------------------------------

map2 <- agged_data$env_obj |> # for readability
  dplyr::filter(env_obj == 'NF1') |> # Need to reduce dimensionality
  plot_outcomes(y_col = 'ewr_achieved',
                x_col = 'map',
                colorgroups = NULL,
                colorset = 'ewr_achieved',
                pal_list = list('ggthemes::Orange-Gold'),
                facet_col = 'scenario',
                facet_row = 'env_obj',
                scene_pal = scene_pal,
                sceneorder = c('down4', 'base', 'up4'),
                underlay_list = list(list(underlay = 'basin',
                                          underlay_pal = 'cornsilk'),
                                     list(underlay = dplyr::filter(obj_sdl_to_plot, env_obj == 'NF1'),
                                          underlay_ycol = 'ewr_achieved',
                                          underlay_pal = 'scico::oslo'))) +
  ggplot2::theme(legend.position = 'bottom')

(map2 +
    theme_werp_toolkit(base_size = 18,
                       axis.text = element_blank(),
                       axis.ticks = element_blank(),
                       legend.position = 'none',
                       strip.text = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)",
                              'map2.png'),
         width = 16, height = 9, units = 'cm', bg = 'transparent')

(map2 +
    theme_werp_toolkit(base_size = 10,
                       axis.text = element_blank(),
                       axis.ticks = element_blank(),
                       legend.position = 'bottom')) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)",
                              'map2.png'),
         width = 12, height = 8, units = 'cm', bg = 'transparent')

# From aggregation notebook

basinagg <- allagg$mdb |>
  dplyr::filter(Objective %in% c('No loss of native fish species'))  %>%
  dplyr::mutate(Objective = stringr::str_wrap(Objective, width = 18)) %>%
  dplyr::left_join(scenarios) %>%
  plot_outcomes(y_col = 'ewr_achieved',
                x_col = 'map',
                colorgroups = NULL,
                colorset = 'ewr_achieved',
                pal_list = list('scico::berlin'),
                facet_col = 'scenario',
                facet_row = 'Objective',
                scene_pal = scene_pal,
                sceneorder = c('down4', 'base', 'up4'))
(basinagg +
    theme_werp_toolkit(base_size = 18,
                       axis.text = element_blank(),
                       axis.ticks = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Presentations\Poster2023)",
                              'basin_agg.png'),
         width = 24, height = 9, units = 'cm', bg = 'transparent')

(basinagg +
    theme_werp_toolkit(base_size = 10,
                       axis.text = element_blank(),
                       axis.ticks = element_blank())) %>%
  ggsave(filename = file.path(r"(C:\Users\galen\Deakin University\QAEL - WERP in house - WERP\Toolkit\Writing\Report2023)",
                              'basin_agg.png'),
         width = 16, height = 6, units = 'cm', bg = 'transparent')
